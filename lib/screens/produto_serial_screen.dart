import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/rastreamento_serial.dart';
import '../services/api_client.dart';
import '../services/estoque_service.dart';
import 'produto_serial_scan_screen.dart';

class ProdutoSerialScreen extends StatefulWidget {
  final ApiClient apiClient;

  const ProdutoSerialScreen({super.key, required this.apiClient});

  @override
  State<ProdutoSerialScreen> createState() => _ProdutoSerialScreenState();
}

class _ProdutoSerialScreenState extends State<ProdutoSerialScreen> {
  late final EstoqueService _service;
  final _serialCtrl = TextEditingController();
  bool _loading = false;
  RastreamentoSerialInfo? _result;
  String? _error;

  bool get _canUseCameraQr {
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
  }

  @override
  void dispose() {
    _serialCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscar([String? rawInput]) async {
    final l10n = AppLocalizations.of(context)!;
    final raw = rawInput ?? _serialCtrl.text;
    final serial = serialFromQrOrText(raw);
    if (serial.isEmpty) {
      setState(() {
        _error = l10n.serialRequired;
        _result = null;
      });
      return;
    }
    _serialCtrl.text = serial;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final info = await _service.buscarPorSerial(serial);
      if (!mounted) return;
      setState(() {
        _result = info;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _result = null;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _abrirScanner() async {
    final raw = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const ProdutoSerialScanScreen(),
      ),
    );
    if (raw == null || raw.isEmpty || !mounted) return;
    await _buscar(raw);
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
        title: Text(l10n.serialTrackTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.serialLookupIntro,
              style: TextStyle(
                color: Colors.blueGrey[200],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _serialCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: l10n.serialNumber,
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: l10n.enterSerialHint,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _buscar(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _loading ? null : () => _buscar(),
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: Text(l10n.search),
                  ),
                ),
                if (_canUseCameraQr) ...[
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    onPressed: _loading ? null : _abrirScanner,
                    icon: const Icon(Icons.qr_code_scanner),
                    tooltip: l10n.readQrCode,
                  ),
                ],
              ],
            ),
            if (!_canUseCameraQr)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.qrOnlyMobile,
                  style: TextStyle(color: Colors.blueGrey[300], fontSize: 12),
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 20),
              _InfoCard(
                cardColor: card,
                borderColor: border,
                info: _result!,
                l10n: l10n,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Color cardColor;
  final Color borderColor;
  final RastreamentoSerialInfo info;
  final AppLocalizations l10n;

  const _InfoCard({
    required this.cardColor,
    required this.borderColor,
    required this.info,
    required this.l10n,
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
            l10n.productAllocationHeading,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _row(l10n.serialLabel, info.numeroSerial),
          if (info.clienteNome != null && info.clienteNome!.isNotEmpty)
            _row(l10n.client, info.clienteNome!),
          if (info.subclienteNome != null && info.subclienteNome!.isNotEmpty)
            _row(l10n.subclientBranchLabel, info.subclienteNome!),
          if (info.unidadeEstoque.isNotEmpty)
            _row(l10n.stockUnitLabel, info.unidadeEstoque),
          if (info.observacoes.isNotEmpty)
            _row(l10n.observationsLabel, info.observacoes),
          if (info.atualizadoEm != null)
            _row(l10n.updatedAtLabel, info.atualizadoEm.toString()),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.blueGrey[300],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
