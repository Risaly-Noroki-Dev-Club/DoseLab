extension DurationFormat on Duration {
  /// "3h 42min" / "12min" / "OVERDUE". Compact form intended for
  /// medication-card next-dose hints.
  String formatShort() {
    if (inMilliseconds <= 0) return 'OVERDUE';
    final h = inHours;
    final m = inMinutes.remainder(60);
    if (h <= 0) return '${m}min';
    return '${h}h ${m}min';
  }
}
