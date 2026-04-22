// CSV de exportação / retorno de pagamento (espelho de `paymentCsv.ts` do portal).

const paymentExportColumns = <String>[
  'expense_id',
  'title',
  'amount',
  'date',
  'category',
  'tipo_despesa_nome',
  'username',
  'description',
];

String escapeCsvCell(Object? value) {
  final s = value == null ? '' : value.toString();
  if (RegExp(r'[",\n\r]').hasMatch(s)) {
    return '"${s.replaceAll('"', '""')}"';
  }
  return s;
}

String buildPaymentExportCsv(List<Map<String, String>> rows) {
  final header = paymentExportColumns.join(',');
  final lines = rows.map((r) {
    return paymentExportColumns.map((c) => escapeCsvCell(r[c])).join(',');
  });
  return '\uFEFF$header\n${lines.join('\n')}\n';
}

List<List<String>> parseCsv(String text) {
  final t = text.replaceFirst(RegExp(r'^\uFEFF'), '');
  final out = <List<String>>[];
  var row = <String>[];
  var cur = '';
  var inQuotes = false;
  for (var i = 0; i < t.length; i++) {
    final c = t[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < t.length && t[i + 1] == '"') {
          cur += '"';
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        cur += c;
      }
    } else if (c == '"') {
      inQuotes = true;
    } else if (c == ',') {
      row.add(cur);
      cur = '';
    } else if (c == '\n') {
      row.add(cur);
      cur = '';
      if (row.any((cell) => cell.trim().isNotEmpty)) {
        out.add(row);
      }
      row = [];
    } else if (c != '\r') {
      cur += c;
    }
  }
  row.add(cur);
  if (row.any((cell) => cell.trim().isNotEmpty)) {
    out.add(row);
  }
  return out;
}

String normHeader(String h) {
  return h
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
      .replaceAll(RegExp(r'\s+'), '_');
}

const _headerAliases = <String, String>{
  'expense_id': 'expense_id',
  'id_despesa': 'expense_id',
  'despesa_id': 'expense_id',
  'payment_date': 'payment_date',
  'data_pagamento': 'payment_date',
  'data_de_pagamento': 'payment_date',
  'payment_reference': 'payment_reference',
  'referencia': 'payment_reference',
  'referencia_pagamento': 'payment_reference',
  'payment_status': 'payment_status',
  'status_pagamento': 'payment_status',
  'status': 'payment_status',
};

class ReturnSpreadsheetRow {
  final String expenseId;
  final String paymentDate;
  final String paymentReference;
  final String paymentStatus;

  ReturnSpreadsheetRow({
    required this.expenseId,
    required this.paymentDate,
    required this.paymentReference,
    required this.paymentStatus,
  });
}

bool isReturnMarkAsPaid(String value) {
  final x = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\u0300-\u036f]'), '');
  if (x.isEmpty) return true;
  const skip = {
    'nao',
    'no',
    '0',
    'false',
    'skip',
    'ignorar',
    'pendente',
    'nao_pago',
    'nao_pagar',
  };
  if (skip.contains(x)) return false;
  const ok = {
    'paid',
    'pago',
    'ok',
    'sim',
    'yes',
    '1',
    'true',
    'paga',
    'liquidado',
    'efetuado',
  };
  return ok.contains(x);
}

List<ReturnSpreadsheetRow> parsePaymentReturnGrid(List<List<String>> grid) {
  if (grid.length < 2) return [];
  final rawHeaders = grid.first.map(normHeader).toList();
  final idx = <String, int>{};
  for (var i = 0; i < rawHeaders.length; i++) {
    final key = _headerAliases[rawHeaders[i]];
    if (key != null) {
      idx[key] = i;
    }
  }
  if (!idx.containsKey('expense_id')) return [];
  final idCol = idx['expense_id']!;
  final dateCol = idx['payment_date'];
  final refCol = idx['payment_reference'];
  final stCol = idx['payment_status'];
  final rows = <ReturnSpreadsheetRow>[];
  for (var r = 1; r < grid.length; r++) {
    final line = grid[r];
    if (idCol >= line.length) continue;
    final id = line[idCol].trim();
    if (id.isEmpty) continue;
    rows.add(
      ReturnSpreadsheetRow(
        expenseId: id,
        paymentDate: dateCol != null && dateCol < line.length
            ? line[dateCol].trim()
            : '',
        paymentReference: refCol != null && refCol < line.length
            ? line[refCol].trim()
            : '',
        paymentStatus: stCol != null && stCol < line.length
            ? line[stCol].trim().toLowerCase()
            : 'paid',
      ),
    );
  }
  return rows;
}
