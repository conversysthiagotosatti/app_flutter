import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
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
      appBar: conversysAppBar(context, titulo),
      body: Center(
        child: Text(
          AppLocalizations.of(context)!.inDevelopment,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

