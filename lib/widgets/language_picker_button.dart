import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/app_locale_scope.dart';

/// Ícone que abre o menu de idioma (PT / EN / sistema).
class LanguagePickerIconButton extends StatelessWidget {
  final Color? iconColor;

  const LanguagePickerIconButton({super.key, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = AppLocaleScope.of(context);
    final current = ctrl.localeOverride;

    return PopupMenuButton<String>(
      icon: Icon(Icons.language, color: iconColor),
      tooltip: l10n.language,
      onSelected: (value) {
        switch (value) {
          case 'system':
            ctrl.setLocaleOverride(null);
            break;
          case 'pt':
            ctrl.setLocaleOverride(const Locale('pt'));
            break;
          case 'en':
            ctrl.setLocaleOverride(const Locale('en'));
            break;
        }
      },
      itemBuilder: (ctx) => [
        CheckedPopupMenuItem(
          value: 'system',
          checked: current == null,
          child: Text(l10n.languageSystem),
        ),
        CheckedPopupMenuItem(
          value: 'pt',
          checked: current?.languageCode == 'pt',
          child: Text(l10n.languagePortuguese),
        ),
        CheckedPopupMenuItem(
          value: 'en',
          checked: current?.languageCode == 'en',
          child: Text(l10n.languageEnglish),
        ),
      ],
    );
  }
}
