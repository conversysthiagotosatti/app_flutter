import 'package:flutter/material.dart';

import '../../models/cliente.dart';
import '../../services/api_client.dart';
import '../../services/clientes_service.dart';

class ClientesTab extends StatefulWidget {
  final ApiClient apiClient;

  const ClientesTab({super.key, required this.apiClient});

  @override
  State<ClientesTab> createState() => _ClientesTabState();
}

class _ClientesTabState extends State<ClientesTab> {
  late final ClientesService _service;
  late Future<List<Cliente>> _future;

  @override
  void initState() {
    super.initState();
    _service = ClientesService(widget.apiClient);
    _future = _service.listarClientes();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Cliente>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erro ao carregar clientes: ${snapshot.error}'),
          );
        }

        final clientes = snapshot.data ?? [];
        if (clientes.isEmpty) {
          return const Center(child: Text('Nenhum cliente encontrado.'));
        }

        return ListView.separated(
          itemCount: clientes.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final c = clientes[index];
            return ListTile(
              leading: CircleAvatar(
                child: Text(
                  c.nome.isNotEmpty ? c.nome[0].toUpperCase() : '?',
                ),
              ),
              title: Text(c.nome),
              subtitle: Text(
                [
                  if (c.documento != null) c.documento!,
                  if (c.email != null) c.email!,
                ].join(' • '),
              ),
              trailing: c.ativo
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.cancel, color: Colors.red),
            );
          },
        );
      },
    );
  }
}

