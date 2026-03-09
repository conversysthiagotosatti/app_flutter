import 'package:flutter/material.dart';

PreferredSizeWidget conversysAppBar(
  String title, {
  List<Widget>? extraActions,
  VoidCallback? onNotificationsTap,
  VoidCallback? onProfileTap,
}) {
  final actions = <Widget>[];
  if (extraActions != null) {
    actions.addAll(extraActions);
  }
  actions.addAll([
    IconButton(
      icon: const Icon(Icons.notifications_none),
      tooltip: 'Notificações',
      onPressed: () {
        if (onNotificationsTap != null) {
          onNotificationsTap();
        }
      },
    ),
    IconButton(
      icon: const Icon(Icons.account_circle),
      tooltip: 'Perfil',
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

