import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/expense_enterprise.dart';
import '../services/api_client.dart';
import '../services/expense_enterprise_service.dart';
import '../widgets/conversys_app_bar.dart';
import 'despesa_form_screen.dart';

class DespesaDetalheScreen extends StatefulWidget {
  final ApiClient apiClient;
  final int clienteId;
  final int expenseId;

  const DespesaDetalheScreen({
    super.key,
    required this.apiClient,
    required this.clienteId,
    required this.expenseId,
  });

  @override
  State<DespesaDetalheScreen> createState() => _DespesaDetalheScreenState();
}

class _DespesaDetalheScreenState extends State<DespesaDetalheScreen> {
  late final ExpenseEnterpriseService _svc;
  bool _loading = true;
  String? _error;
  ExpenseEnterpriseRow? _row;
  List<ExpenseAuditLogRow> _audit = [];

  @override
  void initState() {
    super.initState();
    _svc = ExpenseEnterpriseService(widget.apiClient);
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _svc.fetchExpenseDetail(
        widget.clienteId,
        widget.expenseId,
      );
      final logs = await _svc.fetchAuditLog(
        widget.clienteId,
        widget.expenseId,
      );
      if (!mounted) return;
      setState(() {
        _row = detail;
        _audit = logs;
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

  String _statusLabel(AppLocalizations l10n, String code) {
    switch (code) {
      case 'draft':
        return l10n.expenseStatusDraft;
      case 'pending':
        return l10n.expenseStatusPending;
      case 'approved':
        return l10n.expenseStatusApproved;
      case 'rejected':
        return l10n.expenseStatusRejected;
      case 'audited':
        return l10n.expenseStatusAudited;
      case 'paid':
        return l10n.expenseStatusPaid;
      case 'pending_finance':
        return l10n.expenseStatusPendingFinance;
      case 'finance_approved':
        return l10n.expenseStatusFinanceApproved;
      case 'finance_rejected':
        return l10n.expenseStatusFinanceRejected;
      default:
        return code;
    }
  }

  Uri? _receiptUri(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Uri.tryParse(path);
    }
    final base = ApiClient.baseUrl.replaceAll(RegExp(r'/$'), '');
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.tryParse('$base$p');
  }

  Future<void> _openReceipt() async {
    final u = _receiptUri(_row?.receiptFile);
    if (u == null) return;
    final ok = await launchUrl(u, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL inválida')),
      );
    }
  }

  Future<void> _confirmDelete(AppLocalizations l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.expenseDelete),
        content: Text(l10n.expenseDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.expenseDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _svc.deleteExpense(widget.clienteId, widget.expenseId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.expenseLoadError(e.toString()))),
      );
    }
  }

  Future<String?> _promptComment(String title, AppLocalizations l10n) async {
    final c = TextEditingController();
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          decoration: InputDecoration(hintText: l10n.expenseCommentHint),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, ''),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text),
            child: Text(l10n.continueLabel),
          ),
        ],
      ),
    );
    return v;
  }

  Future<void> _submit(AppLocalizations l10n) async {
    try {
      await _svc.submitExpense(widget.clienteId, widget.expenseId);
      if (!mounted) return;
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.expenseLoadError(e.toString()))),
      );
    }
  }

  Future<void> _approve(AppLocalizations l10n) async {
    final c = await _promptComment(l10n.expenseApprove, l10n);
    if (c == null) return;
    try {
      await _svc.approveExpense(
        widget.clienteId,
        widget.expenseId,
        comment: c,
      );
      if (!mounted) return;
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.expenseLoadError(e.toString()))),
      );
    }
  }

  Future<void> _reject(AppLocalizations l10n) async {
    final c = await _promptComment(l10n.expenseReject, l10n);
    if (c == null) return;
    try {
      await _svc.rejectExpense(
        widget.clienteId,
        widget.expenseId,
        comment: c,
      );
      if (!mounted) return;
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.expenseLoadError(e.toString()))),
      );
    }
  }

  Future<void> _markPaid(AppLocalizations l10n) async {
    try {
      await _svc.finalizeExpense(
        widget.clienteId,
        widget.expenseId,
      );
      if (!mounted) return;
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.expenseLoadError(e.toString()))),
      );
    }
  }

  Future<void> _financeApprove(AppLocalizations l10n) async {
    final c = await _promptComment(l10n.expenseFinanceApprove, l10n);
    if (c == null) return;
    try {
      await _svc.financeApproveExpense(
        widget.clienteId,
        widget.expenseId,
        comment: c,
      );
      if (!mounted) return;
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.expenseLoadError(e.toString()))),
      );
    }
  }

  Future<void> _financeReject(AppLocalizations l10n) async {
    final c = await _promptComment(l10n.expenseFinanceReject, l10n);
    if (c == null) return;
    try {
      await _svc.financeRejectExpense(
        widget.clienteId,
        widget.expenseId,
        comment: c,
      );
      if (!mounted) return;
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.expenseLoadError(e.toString()))),
      );
    }
  }

  Future<void> _sendSap(AppLocalizations l10n) async {
    try {
      final r = await _svc.sapSendExpense(widget.clienteId, widget.expenseId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${r.detail}\n${const JsonEncoder.withIndent('  ').convert(r.sap ?? {})}',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.expenseLoadError(e.toString()))),
      );
    }
  }

  Future<void> _openEdit() async {
    final r = _row;
    if (r == null) return;
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DespesaFormScreen(
          apiClient: widget.apiClient,
          clienteId: widget.clienteId,
          existing: r,
        ),
      ),
    );
    if (mounted && ok == true) {
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const bg = Color(0xFF020617);

    if (_loading) {
      return Scaffold(
        appBar: conversysAppBar(context, l10n.expenseDetail),
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _row == null) {
      return Scaffold(
        appBar: conversysAppBar(context, l10n.expenseDetail),
        backgroundColor: bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error != null ? l10n.expenseLoadError(_error!) : '—',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final r = _row!;
    final st = r.status;

    return Scaffold(
      appBar: conversysAppBar(context, l10n.expenseDetail),
      backgroundColor: bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              r.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusLabel(l10n, st),
              style: TextStyle(color: Colors.blue[200], fontWeight: FontWeight.w600),
            ),
            if (r.agrupamentoTitulo != null &&
                r.agrupamentoTitulo!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${l10n.expenseAgrupamentoTitulo}: ${r.agrupamentoTitulo}',
                style: TextStyle(color: Colors.blueGrey[200], fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            _kv(l10n.expenseFieldAmount, r.amount),
            _kv(l10n.expenseFieldDate, r.date),
            if (r.tipoDespesaNome != null)
              _kv(l10n.expenseTipoDespesa, r.tipoDespesaNome!),
            _kv(l10n.expenseFieldDescription, r.description),
            if (r.location.isNotEmpty) _kv(l10n.expenseFieldLocation, r.location),
            if (r.username != null) _kv(l10n.expenseAuthor, r.username!),
            _kv(l10n.expenseRiskScore, r.riskScore.toStringAsFixed(2)),
            if (r.approvals.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l10n.expenseApprovalsChainTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              ...r.approvals.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'L${a.level} · ${a.status}${a.comment.isNotEmpty ? ' — ${a.comment}' : ''}',
                    style: TextStyle(color: Colors.blueGrey[200], fontSize: 12),
                  ),
                ),
              ),
            ],
            if (r.anomalies.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l10n.expenseAnomaliesTitle,
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              ...r.anomalies.map(
                (a) => Text(
                  '${a.type} (${a.score}): ${a.description}',
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
                ),
              ),
            ],
            if (r.extractedData.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l10n.expenseExtractedTitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                const JsonEncoder.withIndent('  ').convert(r.extractedData),
                style: const TextStyle(
                  color: Colors.white54,
                  fontFamily: 'monospace',
                  fontSize: 10,
                ),
              ),
            ],
            if (_receiptUri(r.receiptFile) != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _openReceipt,
                icon: const Icon(Icons.open_in_new),
                label: Text(l10n.expenseOpenReceipt),
              ),
            ],
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (st == 'draft' || st == 'rejected')
                  FilledButton.tonal(
                    onPressed: _openEdit,
                    child: Text(l10n.expenseEdit),
                  ),
                if (st == 'draft') ...[
                  FilledButton(
                    onPressed: () => _submit(l10n),
                    child: Text(l10n.expenseSubmitApproval),
                  ),
                  OutlinedButton(
                    onPressed: () => _confirmDelete(l10n),
                    child: Text(l10n.expenseDelete),
                  ),
                ],
                if (st == 'pending') ...[
                  FilledButton(
                    onPressed: () => _approve(l10n),
                    child: Text(l10n.expenseApprove),
                  ),
                  OutlinedButton(
                    onPressed: () => _reject(l10n),
                    child: Text(l10n.expenseReject),
                  ),
                ],
                if (st == 'pending_finance') ...[
                  FilledButton(
                    onPressed: () => _financeApprove(l10n),
                    child: Text(l10n.expenseFinanceApprove),
                  ),
                  OutlinedButton(
                    onPressed: () => _financeReject(l10n),
                    child: Text(l10n.expenseFinanceReject),
                  ),
                ],
                if (st == 'finance_approved' ||
                    st == 'approved' ||
                    st == 'audited') ...[
                  FilledButton(
                    onPressed: () => _markPaid(l10n),
                    child: Text(l10n.expenseMarkPaid),
                  ),
                  OutlinedButton(
                    onPressed: () => _sendSap(l10n),
                    child: Text(l10n.expenseSapSend),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            Text(
              l10n.expenseAuditTitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            if (_audit.isEmpty)
              Text(
                '—',
                style: TextStyle(color: Colors.blueGrey[300]),
              )
            else
              ..._audit.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1220),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.action,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${a.username ?? '—'} · ${a.timestamp}',
                            style: TextStyle(
                              color: Colors.blueGrey[200],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              k,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
