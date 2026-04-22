import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/expense_enterprise.dart';
import '../services/api_client.dart';
import '../services/expense_enterprise_service.dart';
import '../widgets/conversys_app_bar.dart';

const _kExpenseClienteId = 'expense_selected_cliente_id';

/// Lista + log de auditoria (`ExpenseAudit.tsx`).
class DespesasAuditoriaScreen extends StatefulWidget {
  final ApiClient apiClient;

  const DespesasAuditoriaScreen({super.key, required this.apiClient});

  @override
  State<DespesasAuditoriaScreen> createState() => _DespesasAuditoriaScreenState();
}

class _DespesasAuditoriaScreenState extends State<DespesasAuditoriaScreen> {
  late final ExpenseEnterpriseService _svc;
  bool _loading = true;
  List<ExpenseClienteRow> _companies = [];
  int? _clienteId;
  List<ExpenseEnterpriseRow> _rows = [];
  int? _selectedId;
  List<ExpenseAuditLogRow> _logs = [];
  bool _logsBusy = false;

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
      if (pick != null) await _loadList(pick);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _persistCliente(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kExpenseClienteId, id);
  }

  Future<void> _loadList(int cid) async {
    setState(() {
      _loading = true;
      _selectedId = null;
      _logs = [];
    });
    try {
      final list = await _svc.fetchExpenses(cid);
      if (!mounted) return;
      setState(() {
        _rows = list.take(100).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadLogs(int cid, int expenseId) async {
    setState(() {
      _logsBusy = true;
      _selectedId = expenseId;
      _logs = [];
    });
    try {
      final l = await _svc.fetchAuditLog(cid, expenseId);
      if (!mounted) return;
      setState(() {
        _logs = l;
        _logsBusy = false;
      });
    } catch (_) {
      if (mounted) setState(() => _logsBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const bg = Color(0xFF020617);

    return Scaffold(
      appBar: conversysAppBar(context, l10n.expenseAuditModuleTile),
      backgroundColor: bg,
      body: Column(
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
                  await _loadList(id);
                },
              ),
            ),
          Expanded(
            flex: 2,
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: _rows.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final r = _rows[i];
                      final sel = _selectedId == r.id;
                      return ListTile(
                        selected: sel,
                        selectedTileColor: const Color(0xFF1E293B),
                        title: Text(
                          '#${r.id} · ${r.title}',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        subtitle: Text(
                          r.status,
                          style: TextStyle(color: Colors.blueGrey[200]),
                        ),
                        onTap: () {
                          final cid = _clienteId;
                          if (cid == null) return;
                          _loadLogs(cid, r.id);
                        },
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 220,
            child: _logsBusy
                ? const Center(child: CircularProgressIndicator())
                : _selectedId == null
                    ? Center(
                        child: Text(
                          l10n.expenseAuditTitle,
                          style: const TextStyle(color: Colors.white38),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          Text(
                            '#$_selectedId',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._logs.map(
                            (a) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${a.timestamp} — ${a.action} — ${a.username ?? '${a.user}'}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (a.details.isNotEmpty)
                                    SelectableText(
                                      const JsonEncoder.withIndent('  ')
                                          .convert(a.details),
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontFamily: 'monospace',
                                        fontSize: 10,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
