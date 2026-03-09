import 'package:flutter/material.dart';

import '../../models/contrato.dart';
import '../../services/api_client.dart';
import '../../services/contratos_service.dart';

class ContratosTab extends StatefulWidget {
  final ApiClient apiClient;

  const ContratosTab({super.key, required this.apiClient});

  @override
  State<ContratosTab> createState() => _ContratosTabState();
}

class _ContratosTabState extends State<ContratosTab> {
  late final ContratosService _service;
  late Future<List<Contrato>> _future;

  @override
  void initState() {
    super.initState();
    _service = ContratosService(widget.apiClient);
    _future = _service.listarContratos();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Contrato>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erro ao carregar contratos: ${snapshot.error}'),
          );
        }

        final contratos = snapshot.data ?? [];
        if (contratos.isEmpty) {
          return const Center(child: Text('Nenhum contrato encontrado.'));
        }

        return ListView.separated(
          itemCount: contratos.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final c = contratos[index];
            return ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(c.titulo),
              subtitle: Text(
                c.cliente.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Início: ${_formatDate(c.dataInicio)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (c.dataFim != null)
                    Text(
                      'Fim: ${_formatDate(c.dataFim!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

