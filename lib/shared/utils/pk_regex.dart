/// PK parsing regular expressions, ported from the original PWA's
/// `parsePK()`. Kept as named constants so the regex source survives
/// future refactors and is greppable.
class PkRegex {
  const PkRegex._();

  static final halfLifeRange = RegExp(
    r'half[- ]life[^0-9]*?(\d+\.?\d*)\s*to\s*(\d+\.?\d*)\s*h',
    caseSensitive: false,
  );
  static final halfLifeAbout = RegExp(
    r'half[- ]life[^0-9]*?about\s*(\d+\.?\d*)\s*h',
    caseSensitive: false,
  );
  static final halfLifeSingle = RegExp(
    r'half[- ]life[^0-9]*?(\d+\.?\d*)\s*h',
    caseSensitive: false,
  );
  static final tmax = RegExp(
    r'(?:peak|maximum|C\s*max)[^0-9]*?(\d+\.?\d*)[^0-9]*?(\d+\.?\d*)?\s*h',
    caseSensitive: false,
  );
  static final steadyState = RegExp(
    r'steady[- ]state[^.]*?(\d+\.?\d*)[^.]*?(day|week|hour)',
    caseSensitive: false,
  );
}
