class ExpenseClienteRow {
  final int id;
  final String name;
  final String document;
  final bool active;

  ExpenseClienteRow({
    required this.id,
    required this.name,
    required this.document,
    required this.active,
  });

  factory ExpenseClienteRow.fromJson(Map<String, dynamic> json) {
    return ExpenseClienteRow(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      document: (json['document'] ?? '') as String,
      active: json['active'] as bool? ?? true,
    );
  }
}

class ExpenseTipoDespesaRow {
  final int id;
  final String nome;
  final String codigo;
  final String? accountCode;
  final int ordem;

  ExpenseTipoDespesaRow({
    required this.id,
    required this.nome,
    required this.codigo,
    this.accountCode,
    required this.ordem,
  });

  factory ExpenseTipoDespesaRow.fromJson(Map<String, dynamic> json) {
    return ExpenseTipoDespesaRow(
      id: json['id'] as int,
      nome: (json['nome'] ?? '') as String,
      codigo: (json['codigo'] ?? '') as String,
      accountCode: json['account_code'] as String?,
      ordem: json['ordem'] as int? ?? 0,
    );
  }
}

class ExpenseCentroCustoRow {
  final int id;
  final String codigo;
  final String nome;
  final int ordem;
  final String? regraDistribuicao;

  ExpenseCentroCustoRow({
    required this.id,
    required this.codigo,
    required this.nome,
    required this.ordem,
    this.regraDistribuicao,
  });

  factory ExpenseCentroCustoRow.fromJson(Map<String, dynamic> json) {
    return ExpenseCentroCustoRow(
      id: json['id'] as int,
      codigo: (json['codigo'] ?? '') as String,
      nome: (json['nome'] ?? '') as String,
      ordem: json['ordem'] as int? ?? 0,
      regraDistribuicao: json['regra_distribuicao'] as String?,
    );
  }
}

class ExpenseCompanyUserRow {
  final int id;
  final String username;

  ExpenseCompanyUserRow({required this.id, required this.username});

  factory ExpenseCompanyUserRow.fromJson(Map<String, dynamic> json) {
    return ExpenseCompanyUserRow(
      id: json['id'] as int,
      username: (json['username'] ?? '') as String,
    );
  }
}

class ExpenseApprovalRow {
  final int id;
  final int level;
  final String status;
  final String comment;

  ExpenseApprovalRow({
    required this.id,
    required this.level,
    required this.status,
    required this.comment,
  });

  factory ExpenseApprovalRow.fromJson(Map<String, dynamic> json) {
    return ExpenseApprovalRow(
      id: json['id'] as int,
      level: json['level'] as int? ?? 0,
      status: (json['status'] ?? '') as String,
      comment: (json['comment'] ?? '') as String,
    );
  }
}

class ExpenseAnomalyRow {
  final int id;
  final String type;
  final double score;
  final String description;

  ExpenseAnomalyRow({
    required this.id,
    required this.type,
    required this.score,
    required this.description,
  });

  factory ExpenseAnomalyRow.fromJson(Map<String, dynamic> json) {
    return ExpenseAnomalyRow(
      id: json['id'] as int,
      type: (json['type'] ?? '') as String,
      score: (json['score'] is num) ? (json['score'] as num).toDouble() : 0,
      description: (json['description'] ?? '') as String,
    );
  }
}

class ExpenseEnterpriseRow {
  final int id;
  final int cliente;
  final int user;
  final String? username;
  final int? userResponsible;
  final String? userResponsibleUsername;
  final int? contrato;
  final int? centroCusto;
  final String title;
  final String description;
  final String amount;
  final int? tipoDespesaId;
  final String? tipoDespesaNome;
  final String category;
  final String date;
  final String location;
  final String status;
  final String? receiptFile;
  final String receiptSha256;
  final Map<String, dynamic> extractedData;
  final double riskScore;
  final int? approvalFlow;
  final List<ExpenseAnomalyRow> anomalies;
  final List<ExpenseApprovalRow> approvals;
  final String createdAt;
  final String updatedAt;

  ExpenseEnterpriseRow({
    required this.id,
    required this.cliente,
    required this.user,
    this.username,
    this.userResponsible,
    this.userResponsibleUsername,
    this.contrato,
    this.centroCusto,
    required this.title,
    required this.description,
    required this.amount,
    this.tipoDespesaId,
    this.tipoDespesaNome,
    required this.category,
    required this.date,
    required this.location,
    required this.status,
    this.receiptFile,
    required this.receiptSha256,
    required this.extractedData,
    required this.riskScore,
    this.approvalFlow,
    required this.anomalies,
    required this.approvals,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExpenseEnterpriseRow.fromJson(Map<String, dynamic> json) {
    final anomaliesRaw = json['anomalies'];
    final approvalsRaw = json['approvals'];
    return ExpenseEnterpriseRow(
      id: json['id'] as int,
      cliente: json['cliente'] as int,
      user: json['user'] as int,
      username: json['username'] as String?,
      userResponsible: json['user_responsible'] as int?,
      userResponsibleUsername: json['user_responsible_username'] as String?,
      contrato: json['contrato'] as int?,
      centroCusto: json['centro_custo'] as int?,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      amount: '${json['amount'] ?? ''}',
      tipoDespesaId: json['tipo_despesa_id'] as int?,
      tipoDespesaNome: json['tipo_despesa_nome'] as String?,
      category: (json['category'] ?? '') as String,
      date: (json['date'] ?? '') as String,
      location: (json['location'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      receiptFile: json['receipt_file'] as String?,
      receiptSha256: (json['receipt_sha256'] ?? '') as String,
      extractedData: json['extracted_data'] is Map<String, dynamic>
          ? json['extracted_data'] as Map<String, dynamic>
          : <String, dynamic>{},
      riskScore: (json['risk_score'] is num)
          ? (json['risk_score'] as num).toDouble()
          : 0,
      approvalFlow: json['approval_flow'] as int?,
      anomalies: anomaliesRaw is List
          ? anomaliesRaw
              .whereType<Map<String, dynamic>>()
              .map(ExpenseAnomalyRow.fromJson)
              .toList()
          : const [],
      approvals: approvalsRaw is List
          ? approvalsRaw
              .whereType<Map<String, dynamic>>()
              .map(ExpenseApprovalRow.fromJson)
              .toList()
          : const [],
      createdAt: (json['created_at'] ?? '') as String,
      updatedAt: (json['updated_at'] ?? '') as String,
    );
  }
}

class ExpenseAuditLogRow {
  final int id;
  final String action;
  final int? user;
  final String? username;
  final String timestamp;
  final Map<String, dynamic> details;

  ExpenseAuditLogRow({
    required this.id,
    required this.action,
    this.user,
    this.username,
    required this.timestamp,
    required this.details,
  });

  factory ExpenseAuditLogRow.fromJson(Map<String, dynamic> json) {
    return ExpenseAuditLogRow(
      id: json['id'] as int,
      action: (json['action'] ?? '') as String,
      user: json['user'] as int?,
      username: json['username'] as String?,
      timestamp: (json['timestamp'] ?? '') as String,
      details: json['details'] is Map<String, dynamic>
          ? json['details'] as Map<String, dynamic>
          : <String, dynamic>{},
    );
  }
}
