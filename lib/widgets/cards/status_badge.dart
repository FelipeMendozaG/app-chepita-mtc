import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

enum StatusBadgeType { success, danger, warning, info, neutral }

/// Small pill used to display statuses ("Aprobado", "En progreso", categories, etc.).
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeType type;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusBadgeType.neutral,
    this.icon,
  });

  (Color, Color) _colors() {
    switch (type) {
      case StatusBadgeType.success:
        return (AppColors.successSoftBg, AppColors.success);
      case StatusBadgeType.danger:
        return (AppColors.dangerSoftBg, AppColors.danger);
      case StatusBadgeType.warning:
        return (AppColors.warningSoftBg, AppColors.warning);
      case StatusBadgeType.info:
        return (AppColors.infoSoftBg, AppColors.info);
      case StatusBadgeType.neutral:
        return (AppColors.border.withValues(alpha: 0.4), AppColors.textMuted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: fg.withValues(alpha: 0.18), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
