import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/contrato.dart';
import '../models/expense_enterprise.dart';
import '../services/api_client.dart';
import '../services/contratos_service.dart';
import '../services/expense_enterprise_service.dart';
import '../widgets/conversys_app_bar.dart';

class DespesaFormScreen extends StatefulWidget {
  final ApiClient apiClient;
  final int clienteId;
  final ExpenseEnterpriseRow? existing;

  /// Pré-preenche `agrupamento_titulo` (fluxo de lote / importação).
  final String? initialAgrupamentoTitulo;

  const DespesaFormScreen({
    super.key,
    required this.apiClient,
    required this.clienteId,
    this.existing,
    this.initialAgrupamentoTitulo,
  });

  @override
  State<DespesaFormScreen> createState() => _DespesaFormScreenState();
}

class _DespesaFormScreenState extends State<DespesaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ExpenseEnterpriseService _svc;
  late final ContratosService _contratosSvc;

  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _amount = TextEditingController();
  final _agrupamento = TextEditingController();

  List<ExpenseTipoDespesaRow> _tipos = [];
  List<ExpenseCentroCustoRow> _centros = [];
  List<Contrato> _contratos = [];

  int? _tipoId;
  int? _ccId;
  int? _contratoId;
  int? _respId;
  DateTime? _date;

  String _clienteDisplay = '';
  String _approverDisplay = '—';
  String _financeApproverDisplay = '—';
  List<String> _agrupamentoHints = [];

  List<int>? _receiptBytes;
  String? _receiptName;

  int? _persistedDraftId;

  bool _loading = true;
  bool _saving = false;
  bool _ocrBusy = false;
  String? _error;

  static const _cardBg = Color(0xFFF8FAFC);
  static const _cardBorder = Color(0xFFE2E8F0);
  static const _labelColor = Color(0xFF64748B);
  static const _textColor = Color(0xFF0F172A);
  static const _dashBorder = Color(0xFF94A3B8);

  bool get _isEdit => widget.existing != null;

  bool get _isReceiptPdf {
    final n = _receiptName?.toLowerCase() ?? '';
    return n.endsWith('.pdf');
  }

  @override
  void initState() {
    super.initState();
    _svc = ExpenseEnterpriseService(widget.apiClient);
    _contratosSvc = ContratosService(widget.apiClient);
    _bootstrap();
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _amount.dispose();
    _agrupamento.dispose();
    super.dispose();
  }

  Future<void> _fillFromOcr(AppLocalizations l10n) async {
    if (_receiptBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.expensePickFile)),
      );
      return;
    }
    setState(() => _ocrBusy = true);
    try {
      final o = await _svc.ocrExtractFromImageBytes(
        _receiptBytes!,
        _receiptName ?? 'receipt.jpg',
      );
      if (!mounted) return;
      final title = o['title'] ?? o['vendor'];
      if (title != null) _title.text = title.toString();
      final amt = o['amount'];
      if (amt != null) {
        _amount.text = amt.toString().replaceAll('.', ',');
      }
      final d = o['date']?.toString();
      if (d != null) {
        final parsed = DateTime.tryParse(d);
        if (parsed != null) _date = parsed;
      }
      final desc = o['description'];
      if (desc != null) _desc.text = desc.toString();
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.expenseLoadError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _ocrBusy = false);
    }
  }

  Future<void> _classifyTipo(AppLocalizations l10n) async {
    if (_receiptBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.expensePickFile)),
      );
      return;
    }
    setState(() => _ocrBusy = true);
    try {
      final o = await _svc.classifyTipoFromImage(
        widget.clienteId,
        _receiptBytes!,
        _receiptName ?? 'receipt.jpg',
      );
      if (!mounted) return;
      final id = o['tipo_despesa_id'];
      int? tid;
      if (id is int) {
        tid = id;
      } else if (id is num) {
        tid = id.toInt();
      }
      if (tid != null && _tipos.any((t) => t.id == tid)) {
        setState(() => _tipoId = tid);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((o['rationale'] ?? '—').toString()),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.expenseLoadError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _ocrBusy = false);
    }
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tipos = await _svc.fetchTiposDespesa();
      final centros = await _svc.fetchCentrosCusto(widget.clienteId);
      List<Contrato> contratos = [];
      try {
        contratos = await _contratosSvc.listarContratos(clienteId: widget.clienteId);
      } catch (_) {}

      List<String> agHints = [];
      try {
        agHints = await _svc.fetchAgrupamentoTitulos(widget.clienteId, meOnly: true);
      } catch (_) {}

      String clienteNome = '';
      final nomePrefs = await widget.apiClient.loadAuthClienteNome();
      final cidAuth = await widget.apiClient.loadAuthClienteId();
      if (cidAuth == widget.clienteId && nomePrefs != null && nomePrefs.isNotEmpty) {
        clienteNome = nomePrefs;
      } else {
        clienteNome = 'Cliente #${widget.clienteId}';
      }

      String apUser = '—';
      String finUser = '—';
      int? respFromProfile;
      final meResp = await widget.apiClient.get('/api/auth/me/');
      if (meResp.statusCode == 200) {
        final me = jsonDecode(meResp.body);
        if (me is Map<String, dynamic>) {
          final u = me['usuario_aprovador_despesas_username']?.toString().trim();
          if (u != null && u.isNotEmpty) apUser = u;
          final f = me['usuario_aprovador_despesas_financeiro_username']?.toString().trim();
          if (f != null && f.isNotEmpty) finUser = f;
          final rawAp = me['usuario_aprovador_despesas_id'];
          if (rawAp is int) {
            respFromProfile = rawAp;
          } else if (rawAp is num) {
            respFromProfile = rawAp.toInt();
          }
        }
      }

      final ex = widget.existing;
      if (ex != null) {
        _persistedDraftId = ex.id;
        _title.text = ex.title;
        _desc.text = ex.description;
        _amount.text = ex.amount.replaceAll('.', ',');
        _tipoId = ex.tipoDespesaId;
        _ccId = ex.centroCusto;
        _respId = ex.userResponsible ?? respFromProfile;
        if (ex.date.isNotEmpty) {
          _date = DateTime.tryParse(ex.date);
        }
        final ag = ex.agrupamentoTitulo;
        if (ag != null && ag.isNotEmpty) {
          _agrupamento.text = ag;
        }
        _contratoId = ex.contrato;
      } else {
        _date = DateTime.now();
        _respId = respFromProfile;
        final ini = widget.initialAgrupamentoTitulo;
        if (ini != null && ini.isNotEmpty) {
          _agrupamento.text = ini;
        }
        if (tipos.isNotEmpty) {
          _tipoId = tipos.first.id;
        }
      }

      if (!mounted) return;
      setState(() {
        _tipos = tipos;
        _centros = centros;
        _contratos = contratos;
        _agrupamentoHints = agHints;
        _clienteDisplay = clienteNome;
        _approverDisplay = apUser;
        _financeApproverDisplay = finUser;
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
    return raw.trim().replaceAll(',', '.');
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

  Future<void> _pickReceiptFromCamera() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 88,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (!mounted) return;
      setState(() {
        _receiptBytes = bytes;
        _receiptName = x.name.isNotEmpty ? x.name : 'comprovante.jpg';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.expenseLoadError('$e'))),
      );
    }
  }

  Future<int?> _performSave() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return null;
    if (_tipoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.expenseTipoDespesa)),
      );
      return null;
    }
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.expenseFieldDate)),
      );
      return null;
    }
    if (_respId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.expenseResponsible)),
      );
      return null;
    }

    final amountNorm = _normalizeAmount(_amount.text);
    if (_receiptBytes != null) {
      final digest = sha256.convert(_receiptBytes!);
      try {
        final dup = await _svc.checkReceiptDuplicate(
          widget.clienteId,
          digest.toString(),
          excludeExpenseId: widget.existing?.id ?? _persistedDraftId,
        );
        if (dup && mounted) {
          final ok = await _confirmDuplicate(l10n);
          if (!ok) return null;
        }
      } catch (_) {}
    }

    final fields = <String, String>{
      'title': _title.text.trim(),
      'description': _desc.text.trim(),
      'amount': amountNorm,
      'tipo_despesa_id': '$_tipoId',
      'date': DateFormat('yyyy-MM-dd').format(_date!),
      'location': '',
      'category_locked': 'false',
      'user_responsible_id': '$_respId',
    };
    if (_ccId != null) {
      fields['centro_custo_id'] = '$_ccId';
    }
    if (_contratoId != null) {
      fields['contrato_id'] = '$_contratoId';
    }
    final ag = _agrupamento.text.trim();
    if (ag.isNotEmpty) {
      fields['agrupamento_titulo'] = ag;
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
        if (!mounted) return null;
        setState(() => _saving = false);
        return widget.existing!.id;
      }
      final draftId = _persistedDraftId;
      if (draftId != null) {
        await _svc.patchExpense(
          widget.clienteId,
          draftId,
          fields: fields,
          files: files,
        );
        if (!mounted) return null;
        setState(() => _saving = false);
        return draftId;
      }
      final row = await _svc.createExpense(
        widget.clienteId,
        fields: fields,
        files: files,
      );
      if (!mounted) return null;
      setState(() => _saving = false);
      return row.id;
    } catch (e) {
      if (!mounted) return null;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
      return null;
    }
  }

  Future<void> _onSavePressed() async {
    final l10n = AppLocalizations.of(context)!;
    final id = await _performSave();
    if (!mounted || id == null) return;
    if (_isEdit) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _persistedDraftId = id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.expenseDraftSavedSnackbar)),
      );
    }
  }

  Future<void> _onSubmitPressed() async {
    final l10n = AppLocalizations.of(context)!;
    final id = await _performSave();
    if (!mounted || id == null) return;
    if (!_isEdit) {
      setState(() => _persistedDraftId = id);
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _svc.submitExpense(widget.clienteId, id);
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.expenseLoadError('$e'))),
      );
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

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: _labelColor,
      ),
    );
  }

  Widget _readOnlyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _dashBorder, style: BorderStyle.solid, width: 1.2),
      ),
      child: Text(
        text.isEmpty ? '—' : text,
        style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _formCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: _textColor, fontSize: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  InputDecoration _fieldDec(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: _labelColor, fontSize: 12),
      hintStyle: TextStyle(color: _labelColor.withValues(alpha: 0.85), fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF005AFF), width: 1.5),
      ),
    );
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l10n.expenseLoadError(_error!),
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              _formCard(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ColoredBox(
                      color: Colors.white,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 240, minHeight: 120),
                        child: Center(
                          child: _receiptBytes == null
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_photo_alternate_outlined, size: 44, color: _labelColor),
                                      const SizedBox(height: 10),
                                      Text(
                                        l10n.expenseReceiptEmptyPreview,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 12, height: 1.35, color: _labelColor),
                                      ),
                                    ],
                                  ),
                                )
                              : (_isReceiptPdf
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.picture_as_pdf, size: 48, color: Colors.red.shade700),
                                          const SizedBox(height: 8),
                                          Text(
                                            _receiptName ?? 'PDF',
                                            style: const TextStyle(color: _textColor, fontSize: 12),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    )
                                  : Image.memory(
                                      Uint8List.fromList(_receiptBytes!),
                                      fit: BoxFit.contain,
                                    )),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.expenseReceiptSection,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.expenseReceiptOcrHint,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: _labelColor.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: _ocrBusy ? null : _pickReceiptFromCamera,
                        icon: const Icon(Icons.photo_camera_outlined, size: 18),
                        label: Text(l10n.expenseTakePhoto),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _pickReceipt,
                        icon: const Icon(Icons.attach_file, size: 18),
                        label: Text(l10n.expensePickFile),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _receiptName ?? l10n.expensePickFile,
                    style: TextStyle(
                      color: _receiptName == null ? _labelColor : const Color(0xFF334155),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_receiptBytes != null) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _ocrBusy ? null : () => _fillFromOcr(l10n),
                          icon: _ocrBusy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.document_scanner_outlined, size: 18),
                          label: Text(l10n.expenseOcrFill),
                        ),
                        OutlinedButton.icon(
                          onPressed: _ocrBusy ? null : () => _classifyTipo(l10n),
                          icon: const Icon(Icons.auto_awesome, size: 18),
                          label: Text(l10n.expenseClassifyTipo),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              _formCard(
                children: [
                  _sectionLabel(l10n.expenseAgrupamentoTitulo),
                  const SizedBox(height: 4),
                  Text(
                    l10n.expenseAgrupamentoHint,
                    style: TextStyle(fontSize: 10, color: _labelColor.withValues(alpha: 0.95)),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _agrupamento,
                    enabled: !_isEdit,
                    style: const TextStyle(color: _textColor),
                    decoration: _fieldDec(
                      l10n.expenseAgrupamentoTitulo,
                      hint: 'Ex.: Viagem SP — mar/2026',
                    ),
                  ),
                  if (_agrupamentoHints.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _agrupamentoHints.take(10).map((t) {
                        return ActionChip(
                          label: Text(t, style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          onPressed: _isEdit
                              ? null
                              : () => setState(() {
                                    _agrupamento.text = t;
                                  }),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, c) {
                      final narrow = c.maxWidth < 520;
                      final childA = Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _sectionLabel(l10n.expenseFieldApprover),
                          const SizedBox(height: 4),
                          Text(
                            l10n.expenseApproverProfileHint,
                            style: TextStyle(fontSize: 10, color: _labelColor.withValues(alpha: 0.95)),
                          ),
                          const SizedBox(height: 6),
                          _readOnlyBox(_approverDisplay),
                        ],
                      );
                      final childB = Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _sectionLabel(l10n.expenseFieldFinanceApprover),
                          const SizedBox(height: 4),
                          Text(
                            l10n.expenseApproverProfileHint,
                            style: TextStyle(fontSize: 10, color: _labelColor.withValues(alpha: 0.95)),
                          ),
                          const SizedBox(height: 6),
                          _readOnlyBox(_financeApproverDisplay),
                        ],
                      );
                      if (narrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            childA,
                            const SizedBox(height: 16),
                            childB,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: childA),
                          const SizedBox(width: 16),
                          Expanded(child: childB),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, c) {
                      final narrow = c.maxWidth < 520;
                      final contratoDd = DropdownButtonFormField<int?>(
                        key: ValueKey('contrato_$_contratoId'),
                        initialValue: _contratoId,
                        decoration: _fieldDec(l10n.expenseContractId.replaceAll(' (opcional)', '')),
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: _textColor, fontSize: 14),
                        isExpanded: true,
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(l10n.expenseContractNone),
                          ),
                          ..._contratos.map(
                            (c) => DropdownMenuItem<int?>(
                              value: c.id,
                              child: Text(
                                c.titulo,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _contratoId = v),
                      );
                      final centroDd = DropdownButtonFormField<int?>(
                        key: ValueKey('cc_$_ccId'),
                        initialValue: _ccId,
                        decoration: _fieldDec(l10n.expenseCentroCusto.replaceAll(' (opcional)', '')),
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: _textColor, fontSize: 14),
                        isExpanded: true,
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(l10n.expenseCentroNone),
                          ),
                          ..._centros.map(
                            (cc) => DropdownMenuItem<int?>(
                              value: cc.id,
                              child: Text(
                                '${cc.codigo} — ${cc.nome}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _ccId = v),
                      );
                      if (narrow) {
                        return Column(
                          children: [
                            contratoDd,
                            const SizedBox(height: 12),
                            centroDd,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: contratoDd),
                          const SizedBox(width: 12),
                          Expanded(child: centroDd),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, c) {
                      final narrow = c.maxWidth < 520;
                      final titleField = TextFormField(
                        controller: _title,
                        style: const TextStyle(color: _textColor),
                        decoration: _fieldDec(l10n.expenseFieldTitle),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? l10n.expenseTitleRequired : null,
                      );
                      final amountField = TextFormField(
                        controller: _amount,
                        style: const TextStyle(color: _textColor),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _fieldDec(l10n.expenseFieldAmount),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return l10n.expenseAmountInvalid;
                          }
                          final n = double.tryParse(_normalizeAmount(v));
                          if (n == null || n <= 0) return l10n.expenseAmountInvalid;
                          return null;
                        },
                      );
                      if (narrow) {
                        return Column(
                          children: [
                            titleField,
                            const SizedBox(height: 12),
                            amountField,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: titleField),
                          const SizedBox(width: 12),
                          Expanded(child: amountField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, c) {
                      final narrow = c.maxWidth < 520;
                      final tipoDd = DropdownButtonFormField<int>(
                        key: ValueKey<Object?>('tipo_${_tipoId}_${_tipos.length}'),
                        initialValue: _tipoId,
                        decoration: _fieldDec(l10n.expenseTipoDespesa),
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: _textColor, fontSize: 13),
                        isExpanded: true,
                        items: _tipos
                            .map(
                              (t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(
                                  t.accountCode != null && t.accountCode!.isNotEmpty
                                      ? '${t.nome} (${t.accountCode})'
                                      : t.nome,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _tipoId = v),
                      );
                      final dateTile = InputDecorator(
                        decoration: _fieldDec(l10n.expenseFieldDate),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _date == null
                                    ? '—'
                                    : DateFormat.yMMMd(l10n.localeName).format(_date!),
                                style: const TextStyle(color: _textColor),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.calendar_month, color: Color(0xFF005AFF)),
                              onPressed: _pickDate,
                            ),
                          ],
                        ),
                      );
                      if (narrow) {
                        return Column(
                          children: [
                            tipoDd,
                            const SizedBox(height: 12),
                            dateTile,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: tipoDd),
                          const SizedBox(width: 12),
                          Expanded(flex: 2, child: dateTile),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _desc,
                    minLines: 3,
                    maxLines: 6,
                    style: const TextStyle(color: _textColor),
                    decoration: _fieldDec(l10n.expenseFieldDescription),
                  ),
                  const SizedBox(height: 18),
                  _sectionLabel(l10n.expenseFieldClient),
                  const SizedBox(height: 6),
                  _readOnlyBox(_clienteDisplay),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton(
                    onPressed: _saving ? null : _onSavePressed,
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.expenseFormSave),
                  ),
                  OutlinedButton(
                    onPressed: _saving ? null : _onSubmitPressed,
                    child: Text(l10n.expenseFormSend),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
