import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/app_locale_scope.dart';

/// Ícone que abre o menu de idioma (mesmas opções do portal + padrão do sistema).
class LanguagePickerIconButton extends StatelessWidget {
  final Color? iconColor;

  const LanguagePickerIconButton({super.key, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = AppLocaleScope.of(context);
    final current = ctrl.menuSelectionCode;

    return PopupMenuButton<String>(
      icon: Icon(Icons.language, color: iconColor),
      tooltip: l10n.language,
      onSelected: ctrl.applyMenuCode,
      itemBuilder: (ctx) => [
        CheckedPopupMenuItem(
          value: 'system',
          checked: current == 'system',
          child: Text(l10n.languageSystem),
        ),
        const PopupMenuDivider(),
        CheckedPopupMenuItem(
          value: 'pt',
          checked: current == 'pt',
          child: const Text('Português (Brasil)'),
        ),
        CheckedPopupMenuItem(
          value: 'ptPT',
          checked: current == 'ptPT',
          child: const Text('Português (Portugal)'),
        ),
        CheckedPopupMenuItem(
          value: 'en',
          checked: current == 'en',
          child: const Text('English'),
        ),
        CheckedPopupMenuItem(
          value: 'es',
          checked: current == 'es',
          child: const Text('Español'),
        ),
        CheckedPopupMenuItem(
          value: 'de',
          checked: current == 'de',
          child: const Text('Deutsch'),
        ),
      ],
    );
  }
}
