/// Lightweight string helpers used across modules.
extension StringX on String {
  /// True if any code point falls in CJK unified ideograph ranges.
  /// Identical predicate to the original PWA's `CJK` regex.
  bool get hasCjk {
    for (final r in runes) {
      if ((r >= 0x4E00 && r <= 0x9FFF) ||
          (r >= 0x3400 && r <= 0x4DBF) ||
          (r >= 0xF900 && r <= 0xFAFF)) {
        return true;
      }
    }
    return false;
  }

  /// Loose containment used by the Chinese name resolver: matches if
  /// either string is a substring of the other.
  bool looseContains(String other) => contains(other) || other.contains(this);
}
