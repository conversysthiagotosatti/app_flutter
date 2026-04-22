import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/expense_enterprise.dart';
import '../services/api_client.dart';
import '../services/expense_enterprise_service.dart';
import '../utils/expense_payment_csv.dart';
import '../widgets/conversys_app_bar.dart';
import 'despesa_detalhe_screen.dart';

const _kExpenseClienteId = 'expense_selected_cliente_id';

/// Pagamentos / SAP / CSV (`ExpensePayments.tsx`).
class DespesasPagamentosScreen extends StatefulWidget {
  final ApiClient apiClient;

  const DespesasPagamentosScreen({super.key, required this.apiClient});

  @override
  State<DespesasPagamentosScreen> createState() =>
      _DespesasPagamentosScreenState();
}

class _DespesasPagamentosScreenState extends State<DespesasPagamentosScreen> {
  late final ExpenseEnterpriseService _svc;
  bool _loading = true;
  List<ExpenseClienteRow> _companies = [];
  int? _clienteId;
  List<ExpenseEnterpriseRow> _rows = [];
  final Set<int> _selected = {};
  bool _sapBulkRunning = false;
  bool _applyBusy = false;
  String? _msg;

  @override
  void initState() {
    super.initState();
    _svc = ExpenseEnterpriseService(widget.apiClient);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    try {
      final list = await _svc.fetchCompanies();
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_kExpenseClienteId);
      int? pick = saved;
      if (pick != null && !list.any((c) => c.id == pick)) pick = null;
      pick ??= list.isNotEmpty ? list.first.id : null;
      if (!mounted) return;
      setState(() {
        _companies = list;
        _clienteId = pick;
        _loading = false;
      });
      if (pick != null) await _load(pick);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _persistCliente(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kExpenseClienteId, id);
  }

  Future<void> _load(int cid) async {
    setState(() {
      _loading = true;
      _msg = null;
    });
    try {
      final raw = await _svc.fetchExpenses(cid, status: 'finance_approved');
      final filtered = raw
          .where((r) => r.status.toLowerCase() == 'finance_approved')
          .toList();
      if (!mounted) return;
      setState(() {
        _rows = filtered;
        _selected.clear();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _msg = e.toString();
      });
    }
  }

  void _toggleAll(AppLocalizations l10n) {
    if (_selected.length == _rows.length) {
      setState(_selected.clear);
    } else {
      setState(() {
        _selected
          ..clear()
          ..addAll(_rows.map((r) => r.id));
      });
    }
  }

  Future<void> _exportCsv(AppLocalizations l10n) async {
    final pick = _rows.where((r) => _selected.contains(r.id)).toList();
    if (pick.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.expenseSelectOne)),
      );
      return;
    }
    final maps = pick
        .map(
          (r) => <String, String>{
            'expense_id': '${r.id}',
            'title': r.title,
            'amount': r.amount,
            'date': r.date,
            'category': r.category,
            'tipo_despesa_nome': r.tipoDespesaNome ?? '',
            'username': r.username ?? '',
            'description': r.description,
          },
        )
        .toList();
    final csv = buildPaymentExportCsv(maps);
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.expenseExportCsvDone)),
    );
  }

  Future<void> _runSapBulk(AppLocalizations l10n) async {
    final cid = _clienteId;
    if (cid == null) return;
    final ids = _rows.where((r) => _selected.contains(r.id)).map((r) => r.id);
    if (ids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.expenseSelectOne)),
      );
      return;
    }
    setState(() {
      _sapBulkRunning = true;
      _msg = null;
    });
    final lines = <String>[];
    for (final id in ids) {
      try {
        final r = await _svc.sapSendExpense(cid, id);
        lines.add('#$id: ${r.detail}');
      } catch (e) {
        lines.add('#$id: $e');
      }
    }
    if (mounted) {
      setState(() {
        _sapBulkRunning = false;
        _msg = lines.join('\n');
      });
    }
  }

  Future<void> _markPaidSelected(AppLocalizations l10n) async {
    final cid = _clienteId;
    if (cid == null) return;
    final ids = _rows.where((r) => _selected.contains(r.id)).map((r) => r.id);
    if (ids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.expenseSelectOne)),
      );
      return;
    }
    setState(() => _applyBusy = true);
    final lines = <String>[];
    for (final id in ids) {
      try {
        await _svc.finalizeExpense(cid, id);
        lines.add('#$id: OK');
      } catch (e) {
        lines.add('#$id: $e');
      }
    }
    if (mounted) {
      setState(() {
        _applyBusy = false;
        _msg = lines.join('\n');
      });
      await _load(cid);
    }
  }

  Future<void> _pickReturnCsv(AppLocalizations l10n) async {
    final cid = _clienteId;
    if (cid == null) return;
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'txt'],
      withData: true,
    );
    if (r == null || r.files.isEmpty || r.files.first.bytes == null) return;
    final text = String.fromCharCodes(r.files.first.bytes!);
    final grid = parseCsv(text);
    final parsed = parsePaymentReturnGrid(grid);
    final approvedIds = _rows.map((e) => e.id).toSet();
    setState(() => _applyBusy = true);
    final results = <String>[];
    for (final row in parsed) {
      final id = int.tryParse(row.expenseId);
      if (id == null || !approvedIds.contains(id)) {
        results.add('${row.expenseId}: ignorado');
        continue;
      }
      if (!isReturnMarkAsPaid(row.paymentStatus)) {
        results.add('${row.expenseId}: status não marca pago');
        continue;
      }
      try {
        await _svc.finalizeExpense(cid, id);
        results.add('${row.expenseId}: pago');
      } catch (e) {
        results.add('${row.expenseId}: $e');
      }
    }
    if (mounted) {
      setState(() {
        _applyBusy = false;
        _msg = '${l10n.expenseApplyReturnResult}:\n${results.join('\n')}';
      });
      await _load(cid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const bg = Color(0xFF020617);

    return Scaffold(
      appBar: conversysAppBar(context, l10n.expensePaymentsScreenTitle),
      backgroundColor: bg,
      body: _loading && _companies.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_companies.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: DropdownButtonFormField<int>(
                      initialValue: _clienteId,
                      decoration: InputDecoration(
                        labelText: l10n.expenseSelectClient,
                        labelStyle: const TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF334155)),
                        ),
                      ),
                      dropdownColor: const Color(0xFF0B1220),
                      style: const TextStyle(color: Colors.white),
                      items: _companies
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (id) async {
                        if (id == null) return;
                        await _persistCliente(id);
                        setState(() => _clienteId = id);
                        await _load(id);
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: _clienteId == null
                            ? null
                            : () => _load(_clienteId!),
                        icon: const Icon(Icons.refresh, color: Colors.white70),
                        label: Text(
                          l10n.expenseRefresh,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _rows.isEmpty ? null : () => _toggleAll(l10n),
                        child: Text(
                          _selected.length == _rows.length
                              ? l10n.expenseDeselectAll
                              : l10n.expenseSelectAll,
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: () => _exportCsv(l10n),
                        child: Text(l10n.expenseExportCsv),
                      ),
                      FilledButton.tonal(
                        onPressed: _sapBulkRunning || _selected.isEmpty
                            ? null
                            : () => _runSapBulk(l10n),
                        child: _sapBulkRunning
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(l10n.expenseSapBulk),
                      ),
                      FilledButton(
                        onPressed: _applyBusy || _selected.isEmpty
                            ? null
                            : () => _markPaidSelected(l10n),
                        child: _applyBusy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(l10n.expenseMarkPaid),
                      ),
                      OutlinedButton(
                        onPressed: _applyBusy ? null : () => _pickReturnCsv(l10n),
                        child: Text(l10n.expenseApplyReturn),
                      ),
                    ],
                  ),
                ),
                if (_msg != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(
                      _msg!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _rows.isEmpty
                          ? Center(
                              child: Text(
                                l10n.expenseEmptyList,
                                style: const TextStyle(color: Colors.white54),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _rows.length,
                              itemBuilder: (context, i) {
                                final r = _rows[i];
                                final sel = _selected.contains(r.id);
                                return CheckboxListTile(
                                  value: sel,
                                  onChanged: (_) {
                                    setState(() {
                                      if (sel) {
                                        _selected.remove(r.id);
                                      } else {
                                        _selected.add(r.id);
                                      }
                                    });
                                  },
                                  title: Text(
                                    r.title,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    '${r.amount} · #${r.id}',
                                    style: TextStyle(color: Colors.blueGrey[200]),
                                  ),
                                  secondary: IconButton(
                                    icon: const Icon(Icons.open_in_new),
                                    color: Colors.white54,
                                    onPressed: () async {
                                      final cid = _clienteId;
                                      if (cid == null) return;
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => DespesaDetalheScreen(
                                            apiClient: widget.apiClient,
                                            clienteId: cid,
                                            expenseId: r.id,
                                          ),
                                        ),
                                      );
                                      if (mounted) await _load(cid);
                                    },
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}
