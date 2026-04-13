import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../clientes_prospectos_screen.dart';

class ClientesTab extends StatefulWidget {
  final ApiClient apiClient;

  const ClientesTab({super.key, required this.apiClient});

  @override
  State<ClientesTab> createState() => _ClientesTabState();
}

class _ClientesTabState extends State<ClientesTab> {
  @override
  Widget build(BuildContext context) {
    return ClientesProspectosScreen(apiClient: widget.apiClient);
  }
}

