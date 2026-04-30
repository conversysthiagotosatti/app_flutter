import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import 'user_account_menu_button.dart';

PreferredSizeWidget conversysAppBar(
  BuildContext context,
  String title, {
  List<Widget>? extraActions,
  VoidCallback? onNotificationsTap,
  VoidCallback? onProfileTap,
  ApiClient? userAccountMenuApiClient,
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
    if (userAccountMenuApiClient != null)
      Padding(
        padding: const EdgeInsetsDirectional.only(end: 4),
        child: Center(
          child: UserAccountMenuButton(
            apiClient: userAccountMenuApiClient,
            style: UserAccountMenuStyle.appBarLight,
          ),
        ),
      )
    else
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
