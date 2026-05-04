import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/expense_enterprise.dart';
import 'api_client.dart';

class ExpenseApiException implements Exception {
  final String message;
  final int? statusCode;

  ExpenseApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// Cliente HTTP do módulo **Despesas Enterprise** (`expense_enterprise` no backend ambiente-conversys).
class ExpenseEnterpriseService {
  final ApiClient apiClient;

  ExpenseEnterpriseService(this.apiClient);

  Map<String, String> _tenantHeaders(int clienteId) {
    final id = '$clienteId';
    return {
      'X-Expense-Cliente-Id': id,
      'X-Expense-Company-Id': id,
    };
  }

  Map<String, dynamic> _tenantQuery(int clienteId, [Map<String, String>? extra]) {
    final q = <String, dynamic>{'cliente': clienteId};
    if (extra != null) {
      for (final e in extra.entries) {
        if (e.value.isNotEmpty) {
          q[e.key] = e.value;
        }
      }
    }
    return q;
  }

  String _detailFromBody(String body) {
    if (body.isEmpty) return '';
    try {
      final j = jsonDecode(body);
      if (j is Map<String, dynamic>) {
        final d = j['detail'];
        if (d is String) return d;
        if (d is List) return d.map((e) => e.toString()).join(' ');
        if (j['message'] is String) return j['message'] as String;
        final parts = <String>[];
        for (final e in j.entries) {
          if (e.key == 'message') continue;
          final v = e.value;
          if (v is List) {
            final strs = v.whereType<String>().toList();
            if (strs.length == v.length) {
              parts.add('${e.key}: ${strs.join(' ')}');
            }
          }
        }
        if (parts.isNotEmpty) return parts.join('; ');
      }
    } catch (_) {
      final t = body.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (t.length > 200) return t.substring(0, 200);
      return t;
    }
    return '';
  }

  void _ensureOk(http.Response r, String action) {
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    final extra = _detailFromBody(r.body);
    final msg = extra.isEmpty
        ? '$action (HTTP ${r.statusCode})'
        : '$action — $extra';
    throw ExpenseApiException(msg, r.statusCode);
  }

  Future<List<ExpenseClienteRow>> fetchCompanies() async {
    final r = await apiClient.get('/api/companies/');
    _ensureOk(r, 'Erro ao carregar clientes (despesas)');
    final decoded = jsonDecode(r.body);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ExpenseClienteRow.fromJson)
        .toList();
  }

  Future<List<ExpenseTipoDespesaRow>> fetchTiposDespesa() async {
    final r = await apiClient.get('/api/tipos-despesa/');
    _ensureOk(r, 'Erro ao carregar tipos de despesa');
    final decoded = jsonDecode(r.body);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ExpenseTipoDespesaRow.fromJson)
        .toList();
  }

  Future<List<ExpenseCentroCustoRow>> fetchCentrosCusto(int clienteId) async {
    final r = await apiClient.get(
      '/api/centros-custo/',
      query: _tenantQuery(clienteId),
      extraHeaders: _tenantHeaders(clienteId),
    );
    _ensureOk(r, 'Erro ao carregar centros de custo');
    final decoded = jsonDecode(r.body);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ExpenseCentroCustoRow.fromJson)
        .toList();
  }

  Future<List<ExpenseCompanyUserRow>> fetchCompanyUsers(int clienteId) async {
    final r = await apiClient.get(
      '/api/company-users/',
      query: _tenantQuery(clienteId),
      extraHeaders: _tenantHeaders(clienteId),
    );
    _ensureOk(r, 'Erro ao carregar usuários do cliente');
    final decoded = jsonDecode(r.body);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ExpenseCompanyUserRow.fromJson)
        .toList();
  }

  /// `id` do usuário autenticado (`GET /api/auth/me/`), para filtro `user_id` na lista.
  Future<int?> fetchAuthUserId() async {
    final r = await apiClient.get('/api/auth/me/');
    if (r.statusCode < 200 || r.statusCode >= 300) return null;
    final decoded = jsonDecode(r.body);
    if (decoded is! Map<String, dynamic>) return null;
    final raw = decoded['id'] ?? decoded['user_id'] ?? decoded['pk'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  /// Títulos de agrupamento; com [meOnly] envia `me_only=1` (só despesas do usuário logado), como no portal.
  Future<List<String>> fetchAgrupamentoTitulos(
    int clienteId, {
    bool meOnly = true,
  }) async {
    final extra = <String, String>{};
    if (meOnly) {
      extra['me_only'] = '1';
    }
    final r = await apiClient.get(
      '/api/expenses/agrupamento-titulos/',
      query: _tenantQuery(clienteId, extra.isEmpty ? null : extra),
      extraHeaders: _tenantHeaders(clienteId),
    );
    _ensureOk(r, 'Erro ao carregar títulos de agrupamento');
    final decoded = jsonDecode(r.body);
    if (decoded is! List) return [];
    return decoded.map((e) => e.toString()).toList();
  }

  Future<List<ExpenseEnterpriseRow>> fetchExpenses(
    int clienteId, {
    String? status,
    String? agrupamentoTitulo,
    String? period,
    String? dateFrom,
    String? dateTo,
    int? userId,
  }) async {
    final extra = <String, String>{};
    if (status != null && status.isNotEmpty) {
      extra['status'] = status;
    }
    if (agrupamentoTitulo != null && agrupamentoTitulo.trim().isNotEmpty) {
      extra['agrupamento_titulo'] = agrupamentoTitulo.trim();
    }
    final p = (period ?? '').trim();
    final usePeriod = p.isNotEmpty && p != 'custom';
    if (usePeriod) {
      extra['period'] = p;
    }
    final df = (dateFrom ?? '').trim();
    final dt = (dateTo ?? '').trim();
    if (df.isNotEmpty) {
      extra['date_from'] = df;
    }
    if (dt.isNotEmpty) {
      extra['date_to'] = dt;
    }
    if (userId != null && userId > 0) {
      extra['user_id'] = '$userId';
    }
    final q = _tenantQuery(clienteId, extra.isEmpty ? null : extra);
    final r = await apiClient.get(
      '/api/expenses/',
      query: q,
      extraHeaders: _tenantHeaders(clienteId),
    );
    _ensureOk(r, 'Erro ao carregar despesas');
    final decoded = jsonDecode(r.body);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ExpenseEnterpriseRow.fromJson)
        .toList();
  }

  Future<ExpenseEnterpriseRow> fetchExpenseDetail(
    int clienteId,
    int expenseId,
  ) async {
    final r = await apiClient.get(
      '/api/expenses/$expenseId/',
      query: _tenantQuery(clienteId),
      extraHeaders: _tenantHeaders(clienteId),
    );
    _ensureOk(r, 'Erro ao carregar despesa');
    final decoded = jsonDecode(r.body);
    if (decoded is! Map<String, dynamic>) {
      throw ExpenseApiException('Resposta inválida da API');
    }
    return ExpenseEnterpriseRow.fromJson(decoded);
  }

  Future<bool> checkReceiptDuplicate(
    int clienteId,
    String sha256Hex, {
    int? excludeExpenseId,
  }) async {
    final extra = <String, String>{
      'sha256': sha256Hex.toLowerCase(),
      if (excludeExpenseId != null) 'exclude_id': '$excludeExpenseId',
    };
    final r = await apiClient.get(
      '/api/expenses/check-receipt-duplicate/',
      query: _tenantQuery(clienteId, extra),
      extraHeaders: _tenantHeaders(clienteId),
    );
    _ensureOk(r, 'Erro ao verificar comprovante duplicado');
    final decoded = jsonDecode(r.body);
    if (decoded is Map<String, dynamic> && decoded['duplicate'] is bool) {
      return decoded['duplicate'] as bool;
    }
    return false;
  }

  Future<ExpenseEnterpriseRow> createExpense(
    int clienteId, {
    required Map<String, String> fields,
    List<http.MultipartFile> files = const [],
  }) async {
    final r = await apiClient.postMultipart(
      '/api/expenses/',
      fields: fields,
      files: files,
      query: _tenantQuery(clienteId),
      extraHeaders: _tenantHeaders(clienteId),
    );
    _ensureOk(r, 'Erro ao criar despesa');
    final decoded = jsonDecode(r.body);
    if (decoded is! Map<String, dynamic>) {
      throw ExpenseApiException('Resposta inválida da API');
    }
    return ExpenseEnterpriseRow.fromJson(decoded);
  }

  Future<ExpenseEnterpriseRow> patchExpense(
    int clienteId,
    int expenseId, {
    required Map<String, String> fields,
    List<http.MultipartFile> files = const [],
  }) async {
    final r = await apiClient.patchMultipart(
      '/api/expenses/$expenseId/',
      fields: fields,
      files: files,
      query: _tenantQuery(clienteId),
      extraHeaders: _tenantHeaders(clienteId),
    );
    _ensureOk(r, 'Erro ao atualizar despesa');
    final decoded = jsonDecode(r.body);
    if (decoded is! Map<String, dynamic>) {
      throw ExpenseApiException('Resposta inválida da API');
    }
    return ExpenseEnterpriseRow.fromJson(decoded);
  }

  Future<void> deleteExpense(int clienteId, int expenseId) async {
    final r = await apiClient.delete(
      '/api/expenses/$expenseId/',
      query: _tenantQuery(clienteId),
      extraHeaders: _tenantHeaders(clienteId),
    );
    if (r.statusCode != 204 && r.statusCode != 200) {
      _ensureOk(r, 'Erro ao excluir despesa');
    }
  }

  Future<ExpenseEnterpriseRow> submitExpense(int clienteId, int expenseId) async {
    final r = await apiClient.post(
      '/api/expenses/$expenseId/submit/',
      body: {},
      query: _tenantQuery(clienteId),
      extraHeaders: _tenantHeaders(clienteId),
    );
    _ensureOk(r, 'Erro ao enviar despesa para aprovação');
    final decoded = jsonDecode(r.body);
    if (decoded is! Map<String, dynamic>) {
      throw ExpenseApiException('Resposta inválida da API');
    }
    return ExpenseEnterpriseRow.fromJson(decoded);
  }

  Future<ExpenseEnterpriseRow> approveExpense(
    int clienteId,
    int expenseId, {
    String comment = '',
  }) async {
    final r = await apiClient.post(
      '/api/expenses/$expenseId/approve/',
      body: {'comment': comment},
      query: _tenantQuery(clienteId),
      extraHeaders: _tenantHeaders(clienteId),
    );
    _ensureOk(r, 'Erro ao aprovar despesa');
    final decoded = jsonDecode(r.body);
    if (decoded is! Map<String, dynamic>) {
      throw ExpenseApiException('Resposta inválida da API');
    }
    return ExpenseEnterpriseRow.fromJson(decoded);
  }

  Future<ExpenseEnterpriseRow> rejectExpense(
    int clienteId,
    int expenseId, {
    String comment = '',
  }) async {
    final r = await apiClient.post(
      '/api/expenses/$expenseId/reject/',
      body: {'comment': comment},
      query: _tenantQuery(clienteId),
      extraHeaders: _tenantHeaders(clienteId),
    );
    _ensureOk(r, 'Erro ao rejeitar despesa');
    final decoded = jsonDecode(r.body);
    if (decoded is! Map<String, dynamic>) {
      throw ExpenseApiException('Resposta inválida da API');
    }
    return ExpenseEnterpriseRow.fromJson(decoded);
  }

  /// Marca como **paga** (API do portal: somente `status: paid`).
  Future<ExpenseEnterpriseRow> finalizeExpense(
    int clienteId,
    int expenseId,
  ) async {
    final r = await apiClient.post(
      '/api/expenses/$expenseId/finalize/',
      body: {'status': 'paid'},
      query: _tenantQuery(clienteId),
      extraHeaders: _tenantHeaders(clienteId),
    );
    _ensureOk(r, 'Erro ao finalizar despesa');
    final decoded = jsonDecode(r.body);
    if (decoded is! Map<String, dynamic>) {
      throw ExpenseApiException('Resposta inválida da API');
    }
    return ExpenseEnterpriseRow.fromJson(decoded);
  }

  Future<List<ExpenseAuditLogRow>> fetchAuditLog(
    int clienteId,
    int expenseId,
  ) async {
    final r = await apiClient.get(
      '/api/expenses/$expenseId/audit-log/',
      query: _tenantQuery(clienteId),
      extraHeaders: _tenantHeaders(clienteId),
    );
    _ensureOk(r, 'Erro ao carregar auditoria');
    final decoded = jsonDecode(r.body);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ExpenseAuditLogRow.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> fetchAnalytics(
    int clienteId, {
    String? dateFrom,
    String? dateTo,
  }) async {
    final extra = <String, String>{
      if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
    };
    final r = await apiClient.get(
      '/api/analytics/expenses/',
      query: _tenantQuery(clienteId, extra),
      extraHeaders: _tenantHeaders(clienteId),
    );
    _ensureOk(r, 'Erro ao carregar analytics');
    final decoded = jsonDecode(r.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {};
  }

  Future<Map<String, dynamic>> ocrExtractFromText(String text) async {
    final r = await apiClient.post(
      '/api/expenses/ocr-extract/',
      body: {'text': text},
    );
    _ensureOk(r, 'Erro no OCR (texto)');
    final decoded = jsonDecode(r.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {};
  }

  Future<Map<String, dynamic>> ocrExtractFromImageBytes(
    List<int> bytes,
    String filename,
  ) async {
    final file = http.MultipartFile.fromBytes(
      'image',
      bytes,
      filename: filename,
    );
    final r = await apiClient.postMultipart(
      '/api/expenses/ocr-extract/',
      fields: {},
      files: [file],
    );
    _ensureOk(r, 'Erro no OCR (imagem)');
    final decoded = jsonDecode(r.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {};
  }

  Future<List<ExpenseGroupSummaryRow>> fetchGroupSummary(int clienteId) async {
    final r = await apiClient.get(
      '/api/expenses/group-summary/',
      query: _tenantQuery(clienteId),
      extraHeaders: _tenantHeaders(clienteId),
    );
    _ensureOk(r, 'Erro ao carregar agrupamentos');
    final decoded = jsonDecode(r.body);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ExpenseGroupSummaryRow.fromJson)
        .toList();
  }

  Future<ExpenseGroupSubmitResult> submitExpenseGroup(
    int clienteId,
    String agrupamentoTitulo,
  ) async {
    final r = await apiClient.post(
      '/api/expenses/submit-group/',
      body: {'agrupamento_titulo': agrupamentoTitulo.trim()},
      query: _tenantQuery(clienteId),
      extraHeaders: _tenantHeaders(clienteId),
    );
    _ensureOk(r, 'Erro ao enviar lote');
    final decoded = jsonDecode(r.body);
    if (decoded is! Map<String, dynamic>) {
      throw ExpenseApiException('Resposta inválida do envio de lote');
    }
    return ExpenseGroupSubmitResult.fromJson(decoded);
  }

  Future<List<ExpensePendingGroupRow>> fetchPendingGroups(int clienteId) async {
    final r = await apiClient.get(
      '/api/expenses/pending-groups/',
      query: _tenantQuery(clienteId),
      extraHeaders: _tenantHeaders(clienteId),
    );
    _ensureOk(r, 'Erro ao carregar grupos pendentes');
    final decoded = jsonDecode(r.body);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ExpensePendingGroupRow.fromJson)
        .toList();
  }

  Future<ExpensePendingGroupBulkResult> approvePendingGroup(
    int clienteId,
    String agrupamentoTitulo, {
    String comment = '',
  }) async {
    final r = await apiClient.post(
      '/api/expenses/pending-groups/approve/',
      body: {
        'agrupamento_titulo': agrupamentoTitulo.trim(),
        'comment': comment,
      },
      query: _tenantQuery(clienteId),
      extraHeaders: _tenantHeaders(clienteId),
    );
    _ensureOk(r, 'Erro ao aprovar grupo');
    final decoded = jsonDecode(r.body);
    if (decoded is! Map<String, dynamic>) {
      throw ExpenseApiException('Resposta inválida');
    }
    return ExpensePendingGroupBulkResult.fromJson(decoded);
  }

  Future<ExpensePendingGroupBulkResult> rejectPendingGroup(
    int clienteId,
    String agrupamentoTitulo, {
    String comment = '',
  }) async {
    final r = await apiClient.post(
      '/api/expenses/pending-groups/reject/',
      body: {
        'agrupamento_titulo': agrupamentoTitulo.trim(),
        'comment': comment,
      },
      query: _tenantQuery(clienteId),
      extraHeaders: _tenantHeaders(clienteId),
    );
    _ensureOk(r, 'Erro ao rejeitar grupo');
    final decoded = jsonDecode(r.body);
    if (decoded is! Map<String, dynamic>) {
      throw ExpenseApiException('Resposta inválida');
    }
    return ExpensePendingGroupBulkResult.fromJson(decoded);
  }

  Future<ExpenseEnterpriseRow> financeApproveExpense(
    int clienteId,
    int expenseId, {
    String comment = '',
  }) async {
    final r = await apiClient.post(
      '/api/expenses/$expenseId/finance-approve/',
      body: {'comment': comment},
      query: _tenantQuery(clienteId),
      extraHeaders: _tenantHeaders(clienteId),
    );
    _ensureOk(r, 'Erro na aprovação financeira');
    final decoded = jsonDecode(r.body);
    if (decoded is! Map<String, dynamic>) {
      throw ExpenseApiException('Resposta inválida');
    }
    return ExpenseEnterpriseRow.fromJson(decoded);
  }

  Future<ExpenseEnterpriseRow> financeRejectExpense(
    int clienteId,
    int expenseId, {
    String comment = '',
  }) async {
    final r = await apiClient.post(
      '/api/expenses/$expenseId/finance-reject/',
      body: {'comment': comment},
      query: _tenantQuery(clienteId),
      extraHeaders: _tenantHeaders(clienteId),
    );
    _ensureOk(r, 'Erro na rejeição financeira');
    final decoded = jsonDecode(r.body);
    if (decoded is! Map<String, dynamic>) {
      throw ExpenseApiException('Resposta inválida');
    }
    return ExpenseEnterpriseRow.fromJson(decoded);
  }

  Future<ExpenseSapSendResponse> sapSendExpense(
    int clienteId,
    int expenseId,
  ) async {
    final r = await apiClient.post(
      '/api/expenses/$expenseId/sap-send/',
      body: <String, dynamic>{},
      query: _tenantQuery(clienteId),
      extraHeaders: _tenantHeaders(clienteId),
    );
    if (r.statusCode < 200 || r.statusCode >= 300) {
      final extra = _detailFromBody(r.body);
      throw ExpenseApiException(
        extra.isEmpty
            ? 'Erro ao enviar ao SAP (${r.statusCode})'
            : extra,
        r.statusCode,
      );
    }
    final decoded = jsonDecode(r.body);
    if (decoded is! Map<String, dynamic>) {
      throw ExpenseApiException('Resposta inválida do SAP');
    }
    return ExpenseSapSendResponse.fromJson(decoded);
  }

  Future<Map<String, dynamic>> classifyTipoFromImage(
    int clienteId,
    List<int> bytes,
    String filename,
  ) async {
    final file = http.MultipartFile.fromBytes(
      'image',
      bytes,
      filename: filename,
    );
    final r = await apiClient.postMultipart(
      '/api/expenses/classify-tipo/',
      fields: const {},
      files: [file],
      query: _tenantQuery(clienteId),
      extraHeaders: _tenantHeaders(clienteId),
    );
    _ensureOk(r, 'Erro ao classificar tipo de despesa');
    final decoded = jsonDecode(r.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {};
  }
}
