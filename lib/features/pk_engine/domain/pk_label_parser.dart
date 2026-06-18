import '../../../shared/utils/pk_regex.dart';

class ParsedPk {
  const ParsedPk({
    this.halfLifeHours,
    this.halfLifeText,
    this.tmaxText,
    this.steadyState,
    this.brand,
    this.generic,
    this.labelId,
  });

  final double? halfLifeHours;
  final String? halfLifeText;
  final String? tmaxText;
  final String? steadyState;
  final String? brand;
  final String? generic;
  final String? labelId;

  bool get isUseful => halfLifeHours != null;
}

/// Parse openFDA `drug/label.json` PK text into structured fields.
/// Behaviour-compatible with the original PWA's `parsePK()` —
/// same regexes, same field naming, same "range → midpoint" rule
/// for half-life expressed as "A to B h".
class PkLabelParser {
  const PkLabelParser();

  ParsedPk? parse(Map<String, dynamic>? labelEnvelope) {
    final results = (labelEnvelope?['results'] as List?) ?? const [];
    if (results.isEmpty) return null;
    final label = results.first as Map<String, dynamic>;
    final txt = ((label['pharmacokinetics'] as List?) ?? const []).join(' ');

    double? hl;
    String? hlText;
    final range = PkRegex.halfLifeRange.firstMatch(txt);
    if (range != null) {
      hl = (double.parse(range.group(1)!) + double.parse(range.group(2)!)) / 2;
      hlText = range.group(0)?.trim();
    } else {
      final about = PkRegex.halfLifeAbout.firstMatch(txt);
      final single = about ?? PkRegex.halfLifeSingle.firstMatch(txt);
      if (single != null) {
        hl = double.tryParse(single.group(1)!);
        hlText = single.group(0)?.trim();
      }
    }

    final tmaxMatch = PkRegex.tmax.firstMatch(txt);
    final tmaxText = tmaxMatch == null
        ? null
        : (tmaxMatch.group(2) == null
            ? '${tmaxMatch.group(1)} h'
            : '${tmaxMatch.group(1)}–${tmaxMatch.group(2)} h');

    final steady = PkRegex.steadyState.firstMatch(txt)?.group(0)?.trim();

    final openfda = (label['openfda'] as Map?) ?? const {};
    return ParsedPk(
      halfLifeHours: hl,
      halfLifeText: hlText,
      tmaxText: tmaxText,
      steadyState: steady,
      brand: (openfda['brand_name'] as List?)?.firstOrNull as String?,
      generic: (openfda['generic_name'] as List?)?.firstOrNull as String?,
      labelId: label['id'] as String?,
    );
  }
}

extension _FirstOrNull on Iterable {
  Object? get firstOrNull => isEmpty ? null : first;
}
