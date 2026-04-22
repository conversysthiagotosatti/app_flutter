import 'package:flutter/material.dart';

import 'app_locale_controller.dart';

class AppLocaleScope extends InheritedNotifier<AppLocaleController> {
  const AppLocaleScope({
    required AppLocaleController super.notifier,
    required super.child,
    super.key,
  });

  static AppLocaleController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    assert(scope != null, 'AppLocaleScope not found above this context');
    return scope!.notifier!;
  }
}
