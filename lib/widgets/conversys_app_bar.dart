import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

PreferredSizeWidget conversysAppBar(
  BuildContext context,
  String title, {
  List<Widget>? extraActions,
  VoidCallback? onNotificationsTap,
  VoidCallback? onProfileTap,
}) {
  final l10n = AppLocalizations.of(context)!;
  final actions = <Widget>[];
  if (extraActions != null) {
    actions.addAll(extraActions);
  }
  actions.addAll([
    IconButton(
      icon: const Icon(Icons.notifications_none),
      tooltip: l10n.notifications,
      onPressed: () {
        if (onNotificationsTap != null) {
          onNotificationsTap();
        }
      },
    ),
    IconButton(
      icon: const Icon(Icons.account_circle),
      tooltip: l10n.profile,
      onPressed: () {
        if (onProfileTap != null) {
          onProfileTap();
        }
      },
    ),
  ]);

  return AppBar(
    title: Text(title),
    actions: actions,
  );
}

