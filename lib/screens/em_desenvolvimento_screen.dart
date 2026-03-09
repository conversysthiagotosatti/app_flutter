import 'package:flutter/material.dart';

import '../widgets/conversys_app_bar.dart';

class EmDesenvolvimentoScreen extends StatelessWidget {
  final String titulo;

  const EmDesenvolvimentoScreen({
    super.key,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: conversysAppBar(titulo),
      body: const Center(
        child: Text(
          'Em Desenvolvimento',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

