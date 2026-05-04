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
  /// Linha extra sob o título (ex.: seletor de empresa no módulo Despesas).
  Widget? subtitle,
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

  final hasSubtitle = subtitle != null;

  return AppBar(
    toolbarHeight: hasSubtitle ? 88 : kToolbarHeight,
    title: hasSubtitle
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              SizedBox(height: 36, child: subtitle),
            ],
          )
        : Text(title),
    actions: actions,
  );
}
