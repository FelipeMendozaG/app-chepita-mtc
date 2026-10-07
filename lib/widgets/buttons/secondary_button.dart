import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Outlined button used for secondary actions ("Anterior", "Cancelar", etc.).
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconAlignment iconAlignment;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconAlignment = IconAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final labelWidget = Text(
      label,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );

    final effectiveOnPressed = onPressed == null
        ? null
        : () {
            HapticFeedback.lightImpact();
            onPressed!();
          };

    if (icon != null) {
      return OutlinedButton.icon(
        onPressed: effectiveOnPressed,
        icon: Icon(icon),
        label: labelWidget,
        iconAlignment: iconAlignment,
      );
    }

    return OutlinedButton(onPressed: effectiveOnPressed, child: labelWidget);
  }
}
