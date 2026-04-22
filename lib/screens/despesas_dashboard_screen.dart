import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../services/expense_enterprise_service.dart';
import '../widgets/conversys_app_bar.dart';

const _kExpenseClienteId = 'expense_selected_cliente_id';

class DespesasDashboardScreen extends StatefulWidget {
  final ApiClient apiClient;

  const DespesasDashboardScreen({super.key, required this.apiClient});

  @override
  State<DespesasDashboardScreen> createState() =>
      _DespesasDashboardScreenState();
}

class _DespesasDashboardScreenState extends State<DespesasDashboardScreen> {
  late final ExpenseEnterpriseService _svc;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;
  List<DropdownMenuItem<int>> _clients = [];
  int? _clienteId;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _svc = ExpenseEnterpriseService(widget.apiClient);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final companies = await _svc.fetchCompanies();
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_kExpenseClienteId);
      int? pick = saved;
      if (pick != null && !companies.any((c) => c.id == pick)) {
        pick = null;
      }
      pick ??= companies.isNotEmpty ? companies.first.id : null;
      if (!mounted) return;
      setState(() {
        _clients = companies
            .map(
              (c) => DropdownMenuItem(
                value: c.id,
                child: Text(
                  c.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList();
        _clienteId = pick;
      });
      if (pick != null) {
        await _loadAnalytics(pick);
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadAnalytics(int clienteId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await _svc.fetchAnalytics(
        clienteId,
        dateFrom: _dateFrom != null
            ? DateFormat('yyyy-MM-dd').format(_dateFrom!)
            : null,
        dateTo:
            _dateTo != null ? DateFormat('yyyy-MM-dd').format(_dateTo!) : null,
      );
      if (!mounted) return;
      setState(() {
        _data = d;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _onClientChanged(int? id) async {
    if (id == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kExpenseClienteId, id);
    setState(() => _clienteId = id);
    await _loadAnalytics(id);
  }

  Future<void> _pickDate(bool isFrom) async {
    final now = DateTime.now();
    final initial = isFrom ? (_dateFrom ?? now) : (_dateTo ?? now);
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
    );
    if (d == null) return;
    setState(() {
      if (isFrom) {
        _dateFrom = d;
      } else {
        _dateTo = d;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const bg = Color(0xFF020617);

    return Scaffold(
      appBar: conversysAppBar(context, l10n.expenseDashboardTile),
      backgroundColor: bg,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_clients.isNotEmpty && _clienteId != null)
              DropdownButtonFormField<int>(
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
                items: _clients,
                onChanged: _onClientChanged,
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(true),
                    child: Text(
                      _dateFrom == null
                          ? l10n.expenseDateFrom
                          : DateFormat.yMMMd().format(_dateFrom!),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(false),
                    child: Text(
                      _dateTo == null
                          ? l10n.expenseDateTo
                          : DateFormat.yMMMd().format(_dateTo!),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l10n.expenseRefresh,
                  onPressed: _clienteId == null
                      ? null
                      : () => _loadAnalytics(_clienteId!),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _dateFrom = null;
                  _dateTo = null;
                });
                final id = _clienteId;
                if (id != null) _loadAnalytics(id);
              },
              child: Text(l10n.expenseClearPeriod),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.expenseAnalyticsHint,
              style: TextStyle(color: Colors.blueGrey[200], fontSize: 12),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(
                l10n.expenseLoadError(_error!),
                style: const TextStyle(color: Colors.redAccent),
              )
            else if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_data == null || _data!.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    l10n.expenseEmptyList,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    const JsonEncoder.withIndent('  ').convert(_data),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
