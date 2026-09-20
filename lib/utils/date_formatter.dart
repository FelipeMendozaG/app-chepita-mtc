/// Friendly, Spanish-locale date/time formatting helpers (no external i18n package).
class AppDateFormatter {
  AppDateFormatter._();

  static const _months = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Oct',
    'Nov',
    'Dic',
  ];

  /// Formats a date as "15 Set 2026, 10:30 AM".
  static String friendly(DateTime? date) {
    if (date == null) return '—';
    final local = date.toLocal();
    final month = _months[local.month - 1];
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final period = local.hour >= 12 ? 'PM' : 'AM';
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day} $month ${local.year}, $hour12:$minute $period';
  }

  /// Formats a duration between two dates as "MM:SS min".
  static String duration(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '—';
    final diff = end.difference(start);
    final minutes = diff.inMinutes.toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds min';
  }
}
