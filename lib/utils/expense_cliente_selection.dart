import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';

/// Mesma chave usada nas telas do módulo Despesas (`*_screen.dart`).
const kExpenseSelectedClienteIdKey = 'expense_selected_cliente_id';

/// Mantém cliente ativo global + seleção usada pelas APIs de despesas.
Future<void> persistExpenseModuleClienteSelection(
  ApiClient api,
  int clienteId,
  String clienteNome,
) async {
  await api.saveAuthClienteContext(
    clienteId: clienteId,
    clienteNome: clienteNome,
  );
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(kExpenseSelectedClienteIdKey, clienteId);
}
