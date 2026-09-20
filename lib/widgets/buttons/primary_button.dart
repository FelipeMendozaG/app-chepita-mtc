import 'package:flutter/material.dart';

/// Filled button with an integrated loading spinner and optional icon.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final IconAlignment iconAlignment;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.iconAlignment = IconAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          );

    final effectiveOnPressed = isLoading ? null : onPressed;

    if (icon != null && !isLoading) {
      return FilledButton.icon(
        onPressed: effectiveOnPressed,
        icon: Icon(icon),
        label: child,
        iconAlignment: iconAlignment,
      );
    }

    return FilledButton(onPressed: effectiveOnPressed, child: child);
  }
}
