import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/expense_enterprise.dart';
import '../services/api_client.dart';
import '../services/expense_enterprise_service.dart';
import '../widgets/conversys_app_bar.dart';

class DespesaFormScreen extends StatefulWidget {
  final ApiClient apiClient;
  final int clienteId;
  final ExpenseEnterpriseRow? existing;

  const DespesaFormScreen({
    super.key,
    required this.apiClient,
    required this.clienteId,
    this.existing,
  });

  @override
  State<DespesaFormScreen> createState() => _DespesaFormScreenState();
}

class _DespesaFormScreenState extends State<DespesaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ExpenseEnterpriseService _svc;

  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _amount = TextEditingController();
  final _loc = TextEditingController();
  final _contrato = TextEditingController();

  List<ExpenseTipoDespesaRow> _tipos = [];
  List<ExpenseCentroCustoRow> _centros = [];
  List<ExpenseCompanyUserRow> _users = [];

  int? _tipoId;
  int? _ccId;
  int? _respId;
  DateTime? _date;

  List<int>? _receiptBytes;
  String? _receiptName;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _svc = ExpenseEnterpriseService(widget.apiClient);
    _bootstrap();
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _amount.dispose();
    _loc.dispose();
    _contrato.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tipos = await _svc.fetchTiposDespesa();
      final centros = await _svc.fetchCentrosCusto(widget.clienteId);
      final users = await _svc.fetchCompanyUsers(widget.clienteId);
      final ex = widget.existing;
      if (ex != null) {
        _title.text = ex.title;
        _desc.text = ex.description;
        _amount.text = ex.amount.replaceAll('.', ',');
        _loc.text = ex.location;
        if (ex.contrato != null) {
          _contrato.text = '${ex.contrato}';
        }
        _tipoId = ex.tipoDespesaId;
        _ccId = ex.centroCusto;
        _respId = ex.userResponsible;
        if (ex.date.isNotEmpty) {
          _date = DateTime.tryParse(ex.date);
        }
      } else {
        _date = DateTime.now();
      }
      if (!mounted) return;
      setState(() {
        _tipos = tipos;
        _centros = centros;
        _users = users;
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

  String _normalizeAmount(String raw) {
    final t = raw.trim().replaceAll(',', '.');
    return t;
  }

  Future<bool> _confirmDuplicate(AppLocalizations l10n) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.expenseDuplicateWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.continueLabel),
          ),
        ],
      ),
    );
    return go == true;
  }

  Future<void> _pickReceipt() async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'pdf'],
      withData: true,
    );
    if (r == null || r.files.isEmpty) return;
    final f = r.files.first;
    if (f.bytes == null) return;
    setState(() {
      _receiptBytes = f.bytes!.toList();
      _receiptName = f.name;
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_tipoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.expenseTipoDespesa)),
      );
      return;
    }
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.expenseFieldDate)),
      );
      return;
    }

    final amountNorm = _normalizeAmount(_amount.text);
    if (_receiptBytes != null) {
      final digest = sha256.convert(_receiptBytes!);
      try {
        final dup = await _svc.checkReceiptDuplicate(
          widget.clienteId,
          digest.toString(),
          excludeExpenseId: widget.existing?.id,
        );
        if (dup && mounted) {
          final ok = await _confirmDuplicate(l10n);
          if (!ok) return;
        }
      } catch (_) {
        /* pré-check opcional */
      }
    }

    final fields = <String, String>{
      'title': _title.text.trim(),
      'description': _desc.text.trim(),
      'amount': amountNorm,
      'tipo_despesa_id': '$_tipoId',
      'date': DateFormat('yyyy-MM-dd').format(_date!),
      'location': _loc.text.trim(),
      'category_locked': 'false',
    };
    if (_ccId != null) {
      fields['centro_custo_id'] = '$_ccId';
    }
    if (_respId != null) {
      fields['user_responsible_id'] = '$_respId';
    }
    final cTxt = _contrato.text.trim();
    if (cTxt.isNotEmpty) {
      fields['contrato_id'] = cTxt;
    }

    final files = <http.MultipartFile>[];
    if (_receiptBytes != null) {
      files.add(
        http.MultipartFile.fromBytes(
          'receipt_file',
          _receiptBytes!,
          filename: _receiptName ?? 'receipt.bin',
        ),
      );
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_isEdit) {
        await _svc.patchExpense(
          widget.clienteId,
          widget.existing!.id,
          fields: fields,
          files: files,
        );
      } else {
        await _svc.createExpense(
          widget.clienteId,
          fields: fields,
          files: files,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
    );
    if (d != null) setState(() => _date = d);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const bg = Color(0xFF020617);

    if (_loading) {
      return Scaffold(
        appBar: conversysAppBar(
          context,
          _isEdit ? l10n.expenseEdit : l10n.expenseNew,
        ),
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: conversysAppBar(
        context,
        _isEdit ? l10n.expenseEdit : l10n.expenseNew,
      ),
      backgroundColor: bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                Text(
                  l10n.expenseLoadError(_error!),
                  style: const TextStyle(color: Colors.redAccent),
                ),
              TextFormField(
                controller: _title,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: l10n.expenseFieldTitle,
                  labelStyle: const TextStyle(color: Colors.white70),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.expenseTitleRequired : null,
              ),
              TextFormField(
                controller: _desc,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.expenseFieldDescription,
                  labelStyle: const TextStyle(color: Colors.white70),
                ),
              ),
              TextFormField(
                controller: _amount,
                style: const TextStyle(color: Colors.white),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.expenseFieldAmount,
                  labelStyle: const TextStyle(color: Colors.white70),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return l10n.expenseAmountInvalid;
                  }
                  final n = double.tryParse(_normalizeAmount(v));
                  if (n == null || n <= 0) return l10n.expenseAmountInvalid;
                  return null;
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _tipoId,
                decoration: InputDecoration(
                  labelText: l10n.expenseTipoDespesa,
                  labelStyle: const TextStyle(color: Colors.white70),
                ),
                dropdownColor: const Color(0xFF0B1220),
                style: const TextStyle(color: Colors.white),
                items: _tipos
                    .map(
                      (t) => DropdownMenuItem(
                        value: t.id,
                        child: Text(t.nome, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _tipoId = v),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.expenseFieldDate,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                subtitle: Text(
                  _date == null ? '—' : DateFormat.yMMMd(l10n.localeName).format(_date!),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_month, color: Colors.white),
                  onPressed: _pickDate,
                ),
              ),
              TextFormField(
                controller: _loc,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: l10n.expenseFieldLocation,
                  labelStyle: const TextStyle(color: Colors.white70),
                ),
              ),
              DropdownButtonFormField<int?>(
                value: _ccId,
                decoration: InputDecoration(
                  labelText: l10n.expenseCentroCusto,
                  labelStyle: const TextStyle(color: Colors.white70),
                ),
                dropdownColor: const Color(0xFF0B1220),
                style: const TextStyle(color: Colors.white),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('—', style: TextStyle(color: Colors.white70)),
                  ),
                  ..._centros.map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text('${c.codigo} — ${c.nome}',
                          overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _ccId = v),
              ),
              DropdownButtonFormField<int?>(
                value: _respId,
                decoration: InputDecoration(
                  labelText: l10n.expenseResponsible,
                  labelStyle: const TextStyle(color: Colors.white70),
                ),
                dropdownColor: const Color(0xFF0B1220),
                style: const TextStyle(color: Colors.white),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('—', style: TextStyle(color: Colors.white70)),
                  ),
                  ..._users.map(
                    (u) => DropdownMenuItem(
                      value: u.id,
                      child: Text(u.username, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _respId = v),
              ),
              TextFormField(
                controller: _contrato,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.expenseContractId,
                  labelStyle: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.expenseReceipt,
                style: const TextStyle(color: Colors.white70),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickReceipt,
                    icon: const Icon(Icons.attach_file),
                    label: Text(l10n.expensePickFile),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _receiptName ?? '',
                      style: TextStyle(color: Colors.blueGrey[200], fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.expenseSaveDraft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
