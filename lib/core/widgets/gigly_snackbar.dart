import 'package:flutter/material.dart';

class GiglySnackbar {
  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: actionLabel != null
              ? SnackBarAction(
                  label: actionLabel,
                  onPressed: onAction ?? () {},
                )
              : null,
        ),
      );
  }

  static void showError(BuildContext context, String message) {
    show(context, message: message);
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message: message);
  }
}
