import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/expense_enterprise.dart';
import '../services/api_client.dart';
import '../services/expense_enterprise_service.dart';
import '../widgets/conversys_app_bar.dart';

const _kExpenseClienteId = 'expense_selected_cliente_id';

int? _matchTipoFromCategory(
  String? cat,
  List<ExpenseTipoDespesaRow> tipos,
) {
  if (cat == null || cat.trim().isEmpty || tipos.isEmpty) return null;
  const map = {
    'viagem': 'viagem',
    'alimentacao': 'alimentacao',
    'alimentação': 'alimentacao',
    'transporte': 'transporte',
    'hospedagem': 'hospedagem',
    'material': 'material',
    'servicos': 'servicos',
    'serviços': 'servicos',
    'outro': 'outros',
    'outros': 'outros',
  };
  final s = cat.trim().toLowerCase();
  final slug = map[s] ?? s;
  for (final t in tipos) {
    if (t.codigo.toLowerCase() == slug) return t.id;
    if (t.nome.toLowerCase() == s) return t.id;
  }
  for (final t in tipos) {
    if (t.codigo == slug) return t.id;
  }
  return tipos.first.id;
}

/// Importação em lote com OCR (`ExpenseBatchUpload.tsx` simplificado).
class DespesasImportacaoLoteScreen extends StatefulWidget {
  final ApiClient apiClient;

  const DespesasImportacaoLoteScreen({super.key, required this.apiClient});

  @override
  State<DespesasImportacaoLoteScreen> createState() =>
      _DespesasImportacaoLoteScreenState();
}

class _DespesasImportacaoLoteScreenState
    extends State<DespesasImportacaoLoteScreen> {
  late final ExpenseEnterpriseService _svc;
  final _agrupamento = TextEditingController();
  List<ExpenseClienteRow> _companies = [];
  int? _clienteId;
  List<ExpenseTipoDespesaRow> _tipos = [];
  bool _loading = true;
  bool _running = false;
  String _log = '';

  @override
  void initState() {
    super.initState();
    _svc = ExpenseEnterpriseService(widget.apiClient);
    _bootstrap();
  }

  @override
  void dispose() {
    _agrupamento.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    try {
      final companies = await _svc.fetchCompanies();
      final tipos = await _svc.fetchTiposDespesa();
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_kExpenseClienteId);
      int? pick = saved;
      if (pick != null && !companies.any((c) => c.id == pick)) pick = null;
      pick ??= companies.isNotEmpty ? companies.first.id : null;
      if (!mounted) return;
      setState(() {
        _companies = companies;
        _clienteId = pick;
        _tipos = tipos;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _persistCliente(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kExpenseClienteId, id);
  }

  String _normAmount(Object? v) {
    if (v == null) return '0.01';
    var s = v.toString().trim().replaceAll(',', '.');
    if (s.isEmpty) return '0.01';
    final n = double.tryParse(s);
    if (n == null || n <= 0) return '0.01';
    return s;
  }

  Future<void> _runImport(AppLocalizations l10n) async {
    final cid = _clienteId;
    final ag = _agrupamento.text.trim();
    if (cid == null) return;
    if (ag.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o título do agrupamento.')),
      );
      return;
    }
    final pick = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'gif'],
      withData: true,
    );
    if (pick == null || pick.files.isEmpty) return;

    setState(() {
      _running = true;
      _log = '';
    });
    final lines = <String>[];
    for (final f in pick.files) {
      if (f.bytes == null) continue;
      final bytes = f.bytes!.toList();
      final name = f.name;
      try {
        final ocr = await _svc.ocrExtractFromImageBytes(bytes, name);
        int? tipoId;
        try {
          final cl = await _svc.classifyTipoFromImage(cid, bytes, name);
          final id = cl['tipo_despesa_id'];
          if (id is int) {
            tipoId = id;
          } else if (id is num) {
            tipoId = id.toInt();
          }
        } catch (_) {
          /* opcional */
        }
        tipoId ??= _matchTipoFromCategory(
          ocr['category']?.toString(),
          _tipos,
        );
        tipoId ??= _tipos.isNotEmpty ? _tipos.first.id : null;
        if (tipoId == null) {
          lines.add('$name: sem tipo de despesa');
          continue;
        }
        final titleRaw =
            (ocr['title'] ?? ocr['vendor'] ?? name).toString().trim();
        final title = '$ag · ${titleRaw.length > 200 ? titleRaw.substring(0, 200) : titleRaw}';
        final amount = _normAmount(ocr['amount']);
        final dateStr = ocr['date']?.toString();
        final date = DateTime.tryParse(dateStr ?? '') ?? DateTime.now();
        final desc = (ocr['description'] ?? '').toString();

        await _svc.createExpense(
          cid,
          fields: {
            'title': title,
            'description': desc,
            'amount': amount,
            'tipo_despesa_id': '$tipoId',
            'date': DateFormat('yyyy-MM-dd').format(date),
            'location': '',
            'category_locked': 'false',
            'agrupamento_titulo': ag,
          },
          files: [
            http.MultipartFile.fromBytes(
              'receipt_file',
              bytes,
              filename: name,
            ),
          ],
        );
        lines.add('$name: rascunho criado');
      } catch (e) {
        lines.add('$name: $e');
      }
    }
    if (mounted) {
      setState(() {
        _running = false;
        _log = lines.join('\n');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const bg = Color(0xFF020617);

    return Scaffold(
      appBar: conversysAppBar(context, l10n.expenseBatchImportTile),
      backgroundColor: bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_companies.isNotEmpty)
                    DropdownButtonFormField<int>(
                      initialValue: _clienteId,
                      decoration: InputDecoration(
                        labelText: l10n.expenseSelectClient,
                        labelStyle: const TextStyle(color: Colors.white70),
                        border: const OutlineInputBorder(),
                      ),
                      dropdownColor: const Color(0xFF0B1220),
                      style: const TextStyle(color: Colors.white),
                      items: _companies
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (id) async {
                        if (id == null) return;
                        await _persistCliente(id);
                        setState(() => _clienteId = id);
                      },
                    ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.expenseBatchImportHint,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _agrupamento,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: l10n.expenseAgrupamentoTitulo,
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _running ? null : () => _runImport(l10n),
                    icon: _running
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file),
                    label: Text(l10n.expenseBatchImportTile),
                  ),
                  if (_log.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    SelectableText(
                      _log,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
